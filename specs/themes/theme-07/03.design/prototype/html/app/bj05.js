/* BJ-05 — Lấy hàng và bàn giao đơn (UIF-05). Màn: SCR-025, SCR-026, SCR-027, SCR-028, SCR-029.
 *
 * Đã viết lại sạch (T7-P gói A1, 2026-10-17): mọi fixture, trạng thái, helper io05*, hàm dựng và xử lý sự kiện của BJ-05
 * nằm ở đây; màn dựng thẳng (ownedFlows), không qua bước sửa sau dựng legacy. Sửa BJ-05: sửa thẳng file này.
 * Dùng chung từ app/core.js: appShell, ds24*, io* (ioSearchBar, ioMatchesSearch, ioFilterRows, ioMetaRow, ioReadCard,
 * ioEmpty, ioResult, resultHero, ioFilterChips… — BJ-06 / 07 cũng dùng), vBanner, deniedBody, loadingBody, esc,
 * escapeAttribute, navigate, render, renderAppScreen, showToast, primaryFooter, onScreenEnter.
 * Còn ở core.js (gỡ ở gói khác): cơ chế handoff-unknown của v350; bumpIO05Source trong công cụ dev; mục SCR-025 /
 * SCR-029 trong v360RootScreens / v360ExitTargets.
 */

const IO05_ACTOR={id:"USR-WH-001",name:"Nguyễn Văn An"};
const io05Orders=[
  {id:"SO-260827-21",customer:"Đại lý An Phú",warehouse:"Kho chính",queue:"ACTIONABLE",partialHandoverAllowed:true,partialPolicyVersion:"FUL-POL-v3",fulfillmentVersion:7,sourceVersion:7,allocationSetId:"AS-21",allocationVersion:4,closed:false,status:"Cần lấy hàng",shortage:0,operationId:"IO-HO-SO26082721-01",lines:[
    {id:"PK-21-01",name:"Nobivac DHPPi",code:"SP-000184",uom:"hộp",baseUom:"hộp",conversionToBase:1,conversionVersion:"UOM-SP000184-v2",quantityStep:1,requestedQty:20,deliveredQty:0,allocations:[
      {id:"AL-21-01",allocatedQty:4,allocatedBaseQty:4,pickedQty:4,consumedQty:0,suggestedLot:"DH2507",lot:"DH2507",overrideReason:"",physicalCorrection:null,eligibleLots:[
        {code:"DH2507",expiryDisplay:"30/06/2027",expiryPrecision:"DAY",pickableQty:4,asOf:"27/08/2026 09:41",snapshotVersion:"LOT-Q-v12",recommended:true},
        {code:"DH2509",expiryDisplay:"09/2027",expiryPrecision:"MONTH",pickableQty:18,asOf:"27/08/2026 09:41",snapshotVersion:"LOT-Q-v12",recommended:false},
        {code:"DH2511",expiryDisplay:"2027",expiryPrecision:"YEAR",pickableQty:22,asOf:"27/08/2026 09:41",snapshotVersion:"LOT-Q-v12",recommended:false}
      ]},
      {id:"AL-21-02",allocatedQty:16,allocatedBaseQty:16,pickedQty:8,consumedQty:0,suggestedLot:"DH2509",lot:"DH2509",overrideReason:"",physicalCorrection:null,eligibleLots:[
        {code:"DH2509",expiryDisplay:"09/2027",expiryPrecision:"MONTH",pickableQty:18,asOf:"27/08/2026 09:41",snapshotVersion:"LOT-Q-v12",recommended:true},
        {code:"DH2511",expiryDisplay:"2027",expiryPrecision:"YEAR",pickableQty:22,asOf:"27/08/2026 09:41",snapshotVersion:"LOT-Q-v12",recommended:false}
      ]}
    ]},
    {id:"PK-21-02",name:"Găng tay khám Nitrile",code:"SP-000271",uom:"hộp",baseUom:"hộp",conversionToBase:1,conversionVersion:"UOM-SP000271-v1",quantityStep:1,requestedQty:6,deliveredQty:0,allocations:[
      {id:"AL-21-03",allocatedQty:6,allocatedBaseQty:6,pickedQty:0,consumedQty:0,suggestedLot:null,lot:null,overrideReason:"",physicalCorrection:null,eligibleLots:[]}
    ]}
  ]},
  {id:"SO-260827-24",customer:"Phòng khám Minh Tâm",warehouse:"Kho chính",queue:"WAITING",partialHandoverAllowed:false,partialPolicyVersion:"FUL-POL-v3",fulfillmentVersion:3,sourceVersion:3,allocationSetId:"AS-24",allocationVersion:2,closed:false,status:"Chờ đơn bán xử lý",shortage:8,operationId:"IO-HO-SO26082724-01",lines:[
    {id:"PK-24-01",name:"Amox 500",code:"SP-000066",uom:"hộp",baseUom:"hộp",conversionToBase:1,conversionVersion:"UOM-SP000066-v1",quantityStep:1,requestedQty:50,deliveredQty:0,allocations:[
      {id:"AL-24-01",allocatedQty:42,allocatedBaseQty:42,pickedQty:0,consumedQty:0,suggestedLot:"AM2508",lot:"AM2508",overrideReason:"",physicalCorrection:null,eligibleLots:[{code:"AM2508",expiryDisplay:"08/2027",expiryPrecision:"MONTH",pickableQty:42,asOf:"27/08/2026 09:41",snapshotVersion:"LOT-Q-v9",recommended:true}]}
    ]},
    {id:"PK-24-02",name:"Vitamin ADE",code:"SP-000099",uom:"chai",baseUom:"chai",conversionToBase:1,conversionVersion:"UOM-SP000099-v1",quantityStep:0.5,requestedQty:10,deliveredQty:0,allocations:[
      {id:"AL-24-02",allocatedQty:10,allocatedBaseQty:10,pickedQty:0,consumedQty:0,suggestedLot:null,lot:null,overrideReason:"",physicalCorrection:null,eligibleLots:[]}
    ]}
  ]}
];
let io05SelectedOrderId="SO-260827-21", io05QueueFilter="ALL", io05Query="";
let io05ActiveLineId="PK-21-01", io05ActiveAllocationId="AL-21-01", io05OverrideOpen=false, io05OverrideLot="", io05OverrideReason="";
let io05PickEditorOpen=false, io05PickDraft="";
let io05HandoverByAllocation={}, io05LastResult=null, io05StaleAppliedForOrder={};
io05Orders.forEach((o) => { o.sourceVersion ??= 1; o.reviewSourceVersion ??= null; o.unknownLocked ??= false; });
function io05CurrentOrder(){return io05Orders.find(o=>o.id===io05SelectedOrderId)||io05Orders.find(o=>!o.closed)||io05Orders[0];}
function io05CurrentLines(){return io05CurrentOrder()?.lines||[];}
function io05LineRequested(line){return Number(line?.requestedQty||0);}
function io05LineDelivered(line){return Number(line?.deliveredQty||0);}
function io05LineRemaining(line){return Math.max(0,io05LineRequested(line)-io05LineDelivered(line));}
function io05AllocationRemainingPicked(a){return Math.max(0,Number(a?.pickedQty||0)-Number(a?.consumedQty||0));}
function io05LinePicked(line){return (line.allocations||[]).reduce((sum,a)=>sum+io05AllocationRemainingPicked(a),0);}
function io05LinePickedCumulative(line){return (line.allocations||[]).reduce((sum,a)=>sum+Number(a.pickedQty||0),0);}
function io05LineAllocated(line){return (line.allocations||[]).reduce((sum,a)=>sum+Number(a.allocatedQty||0),0);}
function io05OrderPickedTotal(order=io05CurrentOrder()){return (order?.lines||[]).reduce((s,l)=>s+io05LinePicked(l),0);}
function io05OrderRemainingTotal(order=io05CurrentOrder()){return (order?.lines||[]).reduce((s,l)=>s+io05LineRemaining(l),0);}
function io05LineStatus(line){const ready=io05LinePicked(line),remaining=io05LineRemaining(line);if(remaining<=0)return {label:"Đã bàn giao",tone:"success"};return ready<=0?{label:"Chưa lấy",tone:"neutral"}:ready<remaining?{label:"Đã lấy một phần",tone:"warning"}:{label:"Đã lấy đủ",tone:"success"};}
function io05OrderStatus(order){
  if(order.closed)return {label:"Đã bàn giao",tone:"success"};
  if(order.queue==="VERIFYING")return {label:"Đang xác minh bàn giao",tone:"warning"};
  if(order.queue==="WAITING")return {label:"Chờ đơn bán",tone:"warning"};
  const picked=io05OrderPickedTotal(order), remaining=io05OrderRemainingTotal(order);
  if(picked<=0)return {label:"Cần lấy hàng",tone:"neutral"};
  if(picked>=remaining)return {label:"Chờ bàn giao",tone:"info"};
  return {label:"Đang lấy hàng",tone:"info"};
}
function io05VisibleOrders(){return io05Orders.filter(o=>!o.closed);}
function io05AllAllocations(order=io05CurrentOrder()){return (order?.lines||[]).flatMap(l=>(l.allocations||[]).map(a=>({line:l,allocation:a})));}
function io05ResetHandover(order=io05CurrentOrder()){io05HandoverByAllocation={};io05AllAllocations(order).forEach(({allocation})=>{const available=io05AllocationRemainingPicked(allocation);if(available>0)io05HandoverByAllocation[allocation.id]=available;});}
function io05SyncHandover(){io05AllAllocations().forEach(({allocation})=>{const available=io05AllocationRemainingPicked(allocation);if(available>0&&io05HandoverByAllocation[allocation.id]==null)io05HandoverByAllocation[allocation.id]=available;});}
io05ResetHandover();
function io05CurrentLine(){return io05CurrentLines().find(l=>l.id===io05ActiveLineId)||io05CurrentLines()[0];}
function io05CurrentAllocation(){const line=io05CurrentLine();return line?.allocations.find(a=>a.id===io05ActiveAllocationId)||line?.allocations?.[0];}
function io05CorrectionPending(a){return Boolean(a?.physicalCorrection&&a.physicalCorrection.status!=="CONFIRMED");}
function io05CanReview(){const order=io05CurrentOrder();const picked=io05OrderPickedTotal(order);const correctionPending=io05AllAllocations(order).some(({allocation})=>io05CorrectionPending(allocation));if(!order||order.queue==="WAITING"||order.queue==="VERIFYING"||picked<=0||correctionPending)return false;return order.partialHandoverAllowed?true:(order.lines||[]).every(l=>io05LinePicked(l)>=io05LineRemaining(l));}
function io05HandoverInvalid(){return io05AllAllocations().some(({allocation})=>{const available=io05AllocationRemainingPicked(allocation);if(available<=0)return false;const q=Number(io05HandoverByAllocation[allocation.id]||0);return q<0||q>available;});}
function io05HandoverTotal(){return io05AllAllocations().reduce((sum,{allocation})=>sum+Number(io05HandoverByAllocation[allocation.id]||0),0);}
function io05PickedTotal(){return io05OrderPickedTotal();}
function io05RemainingAfterHandover(){return Math.max(0,io05OrderRemainingTotal()-io05HandoverTotal());}
function io05HandoverByLine(){const m=new Map();io05AllAllocations().forEach(({line,allocation})=>{const q=Number(io05HandoverByAllocation[allocation.id]||0);if(q>0)m.set(line.id,(m.get(line.id)||0)+q);});return m;}
function io05HandoverProductCount(){return io05HandoverByLine().size;}
function io05RemainingProductCountAfterHandover(){const h=io05HandoverByLine();return io05CurrentLines().filter(line=>Math.max(0,io05LineRemaining(line)-Number(h.get(line.id)||0))>0).length;}
function io05ResultRows(result){
  if(!result)return [];
  const grouped=new Map();
  (result.detail||[]).forEach(d=>{const key=`${d.product}|${d.code}|${d.uom}|${d.lot||''}`;const prev=grouped.get(key)||{product:d.product,code:d.code,uom:d.uom,lot:d.lot||null,qty:0};prev.qty+=Number(d.qty||0);grouped.set(key,prev);});
  return [...grouped.values()];
}
function io05EligibleLotMeta(allocation,code){return (allocation?.eligibleLots||[]).find(x=>(typeof x==='string'?x:x.code)===code);}
function io05ExpiryDisplay(meta){return meta?.expiryDisplay||meta?.expiry||'—';}
function io05ApplyStaleRecovery(){
  const order=io05CurrentOrder(); if(!order||order.id!=="SO-260827-21"||io05StaleAppliedForOrder[order.id])return;
  const line=order.lines.find(l=>l.id==="PK-21-01"); const a=line?.allocations.find(x=>x.id==="AL-21-01"); if(!a)return;
  const oldLot=a.lot, unconsumed=io05AllocationRemainingPicked(a); a.lot="DH2511"; a.pickedQty=Number(a.consumedQty||0);
  if(unconsumed>0)a.physicalCorrection={kind:"STALE",status:"PENDING",oldLot,returnQty:unconsumed,newLot:"DH2511",repickQty:unconsumed,actor:null,confirmedAt:null};
  order.allocationVersion=Number(order.allocationVersion||0)+1; io05StaleAppliedForOrder[order.id]=true;io05ResetHandover(order);
}
function io05CorrectionText(line,a){const c=a?.physicalCorrection;if(!c||c.status==="CONFIRMED")return "";return `Trả ${c.returnQty} ${line.uom} lô ${c.oldLot}; lấy lại ${c.repickQty} ${line.uom} lô ${c.newLot}.`;}
function io05MarkUnknown(order=io05CurrentOrder()){if(!order)return;order.queue="VERIFYING";order.status="Đang xác minh bàn giao";order.verificationOperationId=order.operationId;}
function io05ApplyHandover(){
  const order=io05CurrentOrder();
  if (!order || Number(order.reviewSourceVersion ?? 0) !== Number(order.sourceVersion ?? 0)) {
    stateByScreen["SCR-028"] = "SOURCE_CHANGED";
    if (activeScreenId === "SCR-028") renderAppScreen();
    return null;
  }
  const handed=io05HandoverTotal(); if(!order||handed<=0||order.queue==="VERIFYING")return null;
  const detail=[]; const handoverLines=[];
  io05AllAllocations(order).forEach(({line,allocation})=>{
    const available=io05AllocationRemainingPicked(allocation);const q=Math.min(Number(io05HandoverByAllocation[allocation.id]||0),available);if(q<=0)return;
    detail.push({product:line.name,code:line.code,uom:line.uom,lot:allocation.lot,qty:q});
    handoverLines.push({allocationId:allocation.id,productId:line.code,uom:line.uom,baseUom:line.baseUom,sourceQty:q,actualBaseQty:q*Number(line.conversionToBase||1),lot:allocation.lot,conversionVersion:line.conversionVersion});
    allocation.consumedQty=Number(allocation.consumedQty||0)+q; line.deliveredQty=Number(line.deliveredQty||0)+q;
  });
  const remaining=io05OrderRemainingTotal(order); const full=remaining<=0; const confirmedAt="16/09/2026 13:08";
  const evidence={handoverId:`HO-${order.id}-${String((order.handoverCount||0)+1).padStart(2,'0')}`,operationId:order.operationId,sourceId:order.id,sourceVersion:(order.sourceVersion??order.fulfillmentVersion),warehouse:order.warehouse,actorId:IO05_ACTOR.id,actorName:IO05_ACTOR.name,confirmedAt,allocationSetId:order.allocationSetId,allocationVersion:order.allocationVersion,lines:handoverLines,evidenceHash:`sha256:${order.id}:${order.allocationVersion}:${handoverLines.length}`};
  order.handoverCount=Number(order.handoverCount||0)+1;order.lastHandoverEvidence=evidence;
  if(full){order.closed=true;order.status="Đã bàn giao";}else{order.queue="ACTIONABLE";order.status="Cần tiếp tục";}
  const result={orderId:order.id,customer:order.customer,handed,remaining,full,detail,confirmedAt,evidence};io05LastResult=result;io05ResetHandover(order);return result;
}

function updateIO05AllocationValidation(input){
  const line=io05CurrentLine(); const allocation=line?.allocations.find(a=>a.id===input?.dataset.io05PickedAllocation); if(!allocation)return;
  allocation.pickedQty=Math.max(Number(allocation.consumedQty||0),Number(input.value)||0);
  const invalid=allocation.pickedQty>Number(allocation.allocatedQty||0);
  const err=document.querySelector(`[data-io05-picked-error="${allocation.id}"]`); if(err){err.hidden=!invalid;err.textContent=`Số lượng đã lấy không được vượt ${allocation.allocatedQty} ${line.uom}.`;}
  const btn=document.querySelector('[data-io05-action="save-pick"]'); if(btn)btn.disabled=line.allocations.some(a=>Number(a.pickedQty||0)>Number(a.allocatedQty||0));
}
function updateIO05HandoverValidation(input){
  const id=input.dataset.io05HandoverAllocation;io05HandoverByAllocation[id]=Math.max(0,Number(input.value)||0);
  const invalid=io05HandoverInvalid();const total=io05HandoverTotal();
  const err=document.querySelector('[data-io05-handover-error]');if(err){err.hidden=!invalid;err.textContent='Lượng bàn giao không được vượt lượng đã lấy nhưng chưa bàn giao của từng lô.';}
  const inThis=document.querySelector('[data-io05-summary-in-this]');if(inThis)inThis.textContent=`${io05HandoverProductCount()} dòng hàng`;
  const remaining=document.querySelector('[data-io05-summary-remaining]');if(remaining)remaining.textContent=`${io05RemainingProductCountAfterHandover()} dòng hàng`;
  const btn=document.querySelector('[data-io05-action="confirm-handover"]');if(btn)btn.disabled=invalid||total<=0;
}

function bj05DsTone(tone="neutral") {
  const t=String(tone||"neutral").toLowerCase();
  return t==="success"?"Success":t==="warning"?"Warning":t==="danger"?"Danger":t==="info"?"Info":"Neutral";
}
function bj05ReadOnlyListRow({title,subtitle="",trailing="",leading="package",attrs="",state="Default",density="Default",extraClass=""}) {
  return ds24ListRow({title,subtitle,trailing,leading,attrs,type:"Status",state,density,interactive:false,extraClass:`bj05-readonly-row${extraClass?` ${extraClass}`:""}`});
}
function bj05TextArea(label,value,attrs="",helper="") {
  return `<label class="bj05-textarea" data-ds-component="VTextarea" data-figma-node="522:7212" data-ds-prop-state="Filled"><span class="vet45-text-style-8">${esc(label)}</span><textarea class="bj05-textarea__control vet45-text-style-6" rows="3" ${attrs}>${esc(value)}</textarea>${helper?`<small class="vet45-text-style-11">${esc(helper)}</small>`:""}</label>`;
}
function bj05Link(label,attrs="") {
  return `<button class="bj05-link" type="button" ${attrs} data-ds-component="DS v2 / Link" data-figma-node="4431:10396" data-ds-prop-tone="Default" data-ds-prop-state="Default">${esc(label)}</button>`;
}
function bj05SelectionRow(meta,line) {
  const selected=io05OverrideLot===meta.code;
  const trailing=`<span class="bj05-radio${selected?' is-selected':''}" data-ds-component="VRadio" data-figma-node="522:7410" data-ds-prop-state="${selected?'On':'Off'}" aria-hidden="true"></span>`;
  return ds24ListRow({title:`Lô ${meta.code}`,subtitle:`HSD ${io05ExpiryDisplay(meta)} · Có thể lấy ${meta.pickableQty} ${line.uom}`,trailing,leading:null,attrs:`data-io05-select-lot="${escapeAttribute(meta.code)}" aria-pressed="${selected}" data-selection-value="${selected?'selected':'unselected'}"`,type:"Selection",state:selected?"Selected":"Default",interactive:true,extraClass:`bj05-selection-row${selected?' is-selected':''}`});
}
function bj05OverrideSheet(line,allocation) {
  if(!io05OverrideOpen||!allocation)return "";
  const alternatives=(allocation.eligibleLots||[]).filter(x=>(typeof x==='string'?x:x.code)!==allocation.lot).map(x=>typeof x==='string'?{code:x,expiry:'—',available:'—'}:x);
  const selectedRows=alternatives.map(m=>bj05SelectionRow(m,line)).join('');
  const desc=io05AllocationRemainingPicked(allocation)>0?`Đổi lô cần xác nhận đã trả lô cũ và lấy lại đúng lô mới trước khi bàn giao.`:`Chọn một lô đủ điều kiện trong ${io05CurrentOrder().warehouse}.`;
  const textarea=bj05TextArea('Lý do đổi lô *',io05OverrideReason,'data-io05-override-reason placeholder="Nhập lý do"','Bắt buộc để lưu vết thay đổi.');
  return `<div class="sheet-backdrop bj05-lot-sheet-backdrop" data-io05-override-backdrop><section class="bottom-sheet bj05-lot-sheet" data-ds-component="VBottomSheet" data-figma-node="4695:6353" data-ds-prop-show-title="true" data-ds-prop-title="Chọn lô thay thế" data-composed-from="VBottomSheet,DS v2 / List Row,VRadio,VTextarea,VButton" role="dialog" aria-modal="true" aria-label="Chọn lô thay thế"><div class="sheet-handle" data-ds-internal="VBottomSheet.handle"></div><div class="sheet-title" data-ds-internal="VBottomSheet.title"><h3>Chọn lô thay thế</h3></div><div class="sheet-content bj05-lot-sheet__content" data-ds-internal="VBottomSheet.content"><p class="bj05-lot-sheet__intro">${esc(desc)}</p><div class="bj05-selection-list" data-composed-from="DS v2 / List Row,VRadio">${selectedRows}</div>${textarea}<button class="button button--primary bj05-lot-sheet__cta" data-io05-action="confirm-lot-override" data-ds-component="VButton" data-figma-node="521:529" data-ds-prop-hierarchy="Primary" data-ds-prop-state="${io05OverrideReason.trim()&&io05OverrideLot?'Default':'Disabled'}" data-ds-prop-size="Default" data-ds-prop-leading-icon="false" type="button" ${io05OverrideReason.trim()&&io05OverrideLot?'':'disabled'}>Dùng lô này</button></div></section></div>`;
}
function bj05ResultDetails(result) {
  if(!result)return "";
  const actual=io05ResultRows(result);
  const actualRows=actual.map(x=>bj05ReadOnlyListRow({title:x.product,subtitle:`${x.code} · ${x.lot?`Lô ${x.lot}`:'Không theo lô'}`,trailing:`<strong class="bj05-row-quantity">${x.qty} ${esc(x.uom)}</strong>`})).join('');
  const remaining=io05CurrentLines().filter(l=>io05LineRemaining(l)>0);
  const remainingRows=remaining.map(l=>bj05ReadOnlyListRow({title:l.name,subtitle:`${l.code} · Còn cần lấy`,trailing:`<strong class="bj05-row-quantity">${io05LineRemaining(l)} ${esc(l.uom)}</strong>`})).join('');
  return `${actualRows?`<section class="bj05-section" data-ds-component="VSection" data-composed-from="DS v2 / List Row">${ds24SectionTitle('Bàn giao thực tế',`${actual.length} phần hàng`)}<div class="ds24-list-stack">${actualRows}</div></section>`:''}${remainingRows?`<section class="bj05-section" data-ds-component="VSection" data-composed-from="DS v2 / List Row">${ds24SectionTitle('Còn lại',`${remaining.length} dòng hàng`)}<div class="ds24-list-stack">${remainingRows}</div></section>`:''}`;
}

function render025BJ05(state){
  const subtitle="Từ đơn bán đã sẵn sàng xuất kho";
  if(state==="PERMISSION_DENIED") return appShell({title:"Đơn cần lấy hàng",subtitle,body:deniedBody(),centered:true,back:false});
  if(state==="LOADING") return appShell({title:"Đơn cần lấy hàng",subtitle,body:loadingBody(),back:false});
  const filters=[["ALL","Tất cả"],["ACTIONABLE","Cần lấy"],["WAITING","Đang chờ"]];
  if(state==="EMPTY") return appShell({title:"Đơn cần lấy hàng",subtitle,body:`<div class="bj05-chip-scroll">${filters.map(([k,l])=>ds24Chip(k,l,io05QueueFilter===k,'data-io05-filter')).join('')}</div>${ioEmpty("Chưa có đơn cần xử lý","Các đơn cần lấy hoặc đang chờ đơn bán xử lý sẽ xuất hiện tại đây.")}`,centered:true,back:false});
  const source=io05VisibleOrders();
  const filtered=source.filter(o=>(io05QueueFilter==="ALL"||o.queue===io05QueueFilter)&&ioMatchesSearch(io05Query,`${o.id} ${o.customer}`));
  const rows=filtered.map(o=>{const st=io05OrderStatus(o);const status=ds24Badge(st.label,bj05DsTone(st.tone));const attrs=`data-io05-search-text="${escapeAttribute(ioNormalizeSearch(`${o.id} ${o.customer}`))}"`;const disabled=o.queue==="WAITING"||o.queue==="VERIFYING";return ds24ListRow({title:o.id,subtitle:`${o.customer} · ${o.warehouse}`,trailing:status,attrs:`data-io05-order="${escapeAttribute(o.id)}" ${attrs}`,type:'Navigation',state:disabled?'Disabled':'Default',disabled});}).join('');
  const search=ds24Search(io05Query,'data-io05-search','Tìm mã đơn hoặc khách hàng');
  const chips=`<div class="bj05-chip-scroll" aria-label="Lọc đơn cần lấy" data-composed-from="VChip">${filters.map(([k,l])=>ds24Chip(k,l,io05QueueFilter===k,'data-io05-filter')).join('')}</div>`;
  const body=`${search}${chips}${rows?`<section class="ds24-list-stack bj05-queue" data-composed-from="DS v2 / List Row,VBadge">${rows}</section>`:''}<div data-io05-filter-empty ${filtered.length?'hidden':''}>${ioEmpty("Không tìm thấy đơn phù hợp","Thử mã đơn, tên khách hàng hoặc đổi bộ lọc.")}</div>`;
  return appShell({title:"Đơn cần lấy hàng",subtitle,body,back:false});
}
function render026BJ05(state){
  if(state==="PERMISSION_DENIED") return appShell({title:"Hàng cần lấy",body:deniedBody(),centered:true});
  if(state==="LOADING") return appShell({title:"Hàng cần lấy",body:loadingBody()});
  if(state==="STALE_RECOVERED") io05ApplyStaleRecovery();
  const order=io05CurrentOrder(); const lines=io05CurrentLines(); const waiting=order.queue==="WAITING"||state==="SHORTAGE";const verifying=order.queue==="VERIFYING";
  const context=ds24InfoGroup('Thông tin đơn',`${ds24InfoRow('Đơn',order.id)}${ds24InfoRow('Khách hàng',order.customer)}${ds24InfoRow('Kho',order.warehouse)}`,'bj05-context');
  const corrections=io05AllAllocations(order).filter(({allocation})=>io05CorrectionPending(allocation)).map(({line,allocation})=>io05CorrectionText(line,allocation)).filter(Boolean);
  const stale=corrections.length?vBanner("warning","Cần điều chỉnh hàng đang cầm",corrections.join(' ')):"";
  const shortage=waiting?vBanner("warning","Chờ đơn bán xử lý","Đơn chưa đủ hàng để tiếp tục. Kho không tự đổi kho hoặc giảm lượng của đơn."):"";
  const verification=verifying?vBanner("warning","Đang xác minh bàn giao","Không lấy hoặc bàn giao lại đơn này cho tới khi kết quả lần bàn giao trước được xác minh."):"";
  const rows=lines.map(l=>{const lotItems=l.allocations.filter(a=>a.lot);const lots=lotItems.length===1?`Lô ${lotItems[0].lot}`:(lotItems.length>1?`${lotItems.length} lô`:"Không theo lô");const progress=`${io05LinePicked(l)}/${io05LineRemaining(l)} ${l.uom}`;const disabled=waiting||verifying||io05LineRemaining(l)<=0;return ds24ListRow({title:l.name,subtitle:`${l.code} · ${lots}`,trailing:`<strong class="bj05-row-quantity">${io05LineRemaining(l)<=0?'Đã bàn giao':progress}</strong>`,leading:'package',attrs:`data-io05-line="${escapeAttribute(l.id)}"`,type:'Navigation',state:disabled?'Disabled':'Default',disabled});}).join('');
  const activeLines=lines.filter(l=>io05LineRemaining(l)>0);const done=activeLines.filter(l=>io05LinePicked(l)>=io05LineRemaining(l)).length;const partialReady=!waiting&&!verifying&&order.partialHandoverAllowed&&io05OrderPickedTotal(order)>0&&done<activeLines.length;const partialHint=partialReady?`<p class="bj05-decision-note" data-ds-component="VText"><strong>Có thể bàn giao phần đã lấy.</strong> Phần còn lại tiếp tục ở đơn này.</p>`:"";
  const body=`${context}${stale}${shortage}${verification}<section class="bj05-section" data-ds-component="VSection" data-composed-from="DS v2 / List Row">${ds24SectionTitle("Hàng cần lấy",verifying?'Đang xác minh':waiting?'Chờ đơn bán xử lý':`${done}/${activeLines.length} dòng đã lấy đủ`)}<div class="ds24-list-stack">${rows}</div></section>${partialHint}<p class="bj05-business-note" data-ds-component="VText">Tồn vật lý chỉ giảm khi xác nhận bàn giao.</p>`;
  return appShell({title:"Hàng cần lấy",body,actions:waiting||verifying?"":primaryFooter("Rà soát bàn giao",'data-io05-action="review-handover"',!io05CanReview())});
}
function bj05PickEditorSheet(line,allocation){
  if(!io05PickEditorOpen||!allocation)return "";
  const meta=allocation.lot?io05EligibleLotMeta(allocation,allocation.lot):null;const label=allocation.lot?`Lô ${allocation.lot}`:"Không theo lô";const step=Number(line.quantityStep||1);const helper=`Tối đa ${allocation.allocatedQty} ${line.uom}`;const canChange=Number(allocation.consumedQty||0)<=0&&allocation.suggestedLot&&allocation.eligibleLots?.some(x=>(typeof x==='string'?x:x.code)!==allocation.lot);
  const c=allocation.physicalCorrection;const correction=io05CorrectionPending(allocation)?`${vBanner("warning","Cần xác nhận điều chỉnh vật lý",io05CorrectionText(line,allocation),"","Compact")}${Number(allocation.pickedQty||0)>=Number(c.repickQty||0)?`<button class="button button--secondary button--full" data-io05-action="confirm-physical-correction" type="button" data-ds-component="VButton">Xác nhận đã điều chỉnh hàng</button>`:''}`:"";
  return `<div class="sheet-backdrop bj05-pick-editor-backdrop" data-io05-pick-editor-backdrop><section class="bottom-sheet bj05-pick-editor-sheet" data-ds-component="VBottomSheet" data-figma-node="4695:6353" role="dialog" aria-modal="true" aria-label="Cập nhật lượng đã lấy"><div class="sheet-handle"></div><div class="sheet-title"><h3>${esc(label)}</h3></div><div class="sheet-content bj05-pick-editor-sheet__content"><p class="bj05-pick-editor-sheet__meta">${[meta?`HSD ${io05ExpiryDisplay(meta)}`:"",`Cần lấy ${allocation.allocatedQty} ${line.uom}`].filter(Boolean).map(esc).join(' · ')}</p>${correction}${ds24TextField('Đã lấy',io05PickDraft,`data-io05-pick-draft type="number" min="${allocation.consumedQty||0}" max="${allocation.allocatedQty}" step="${step}" inputmode="decimal"`,helper)}${canChange?`<button class="button button--secondary bj05-pick-editor-sheet__change" data-io05-open-override="${escapeAttribute(allocation.id)}" type="button" data-ds-component="VButton">Đổi lô</button>`:""}<button class="button button--primary bj05-pick-editor-sheet__save" data-io05-action="update-pick-allocation" type="button" data-ds-component="VButton" ${Number(io05PickDraft)<Number(allocation.consumedQty||0)||Number(io05PickDraft)>Number(allocation.allocatedQty)?'disabled':''}>Cập nhật</button></div></section></div>`;
}
function render027BJ05(state){
  if(state==="PERMISSION_DENIED") return appShell({title:"Chi tiết lấy hàng",body:deniedBody(),centered:true});
  const line=io05CurrentLine(); if(!line) return appShell({title:"Chi tiết lấy hàng",body:ioEmpty("Không còn hàng cần lấy","Quay lại danh sách để chọn đơn khác."),centered:true});
  const productHead=bj05ReadOnlyListRow({title:line.name,subtitle:`${line.code} · ${line.uom}`,leading:'package',attrs:'data-ds-role="picking-product-summary" data-layout-role="product-context"',density:'Compact',extraClass:'bj05-pick-product-row'});
  const remainingFact=`<section class="bj05-section bj05-remaining-fact" data-ds-component="VSection" data-composed-from="DS v2 / Key-value Row">${ds24KeyValueRow('Còn cần lấy',`${io05LineRemaining(line)} ${line.uom}`,true)}</section>`;
  const rows=line.allocations.map(a=>{const changed=a.lot!==a.suggestedLot;const label=a.lot?`Lô ${a.lot}`:"Không theo lô";const progress=`Cần ${a.allocatedQty} ${line.uom} · Đã lấy ${Number(a.pickedQty||0)} ${line.uom}${Number(a.consumedQty||0)>0?` · Đã bàn giao ${a.consumedQty}`:''}`;return ds24ListRow({title:label,subtitle:`${changed?'Đã đổi · ':''}${progress}`,attrs:`data-io05-pick-allocation="${escapeAttribute(a.id)}"`,type:'Navigation',state:'Default',density:'Default'});}).join('');
  const allocation=io05CurrentAllocation();const hasCorrection=line.allocations.some(a=>io05CorrectionPending(a));const stateNotice=state==="STALE_RECOVERED"&&!hasCorrection?vBanner("warning","Danh sách lô đã thay đổi","Kiểm lại lô hiện hành trước khi lưu lượng đã lấy."):"";const invalid=line.allocations.some(a=>Number(a.pickedQty||0)>Number(a.allocatedQty||0));
  const body=`${productHead}${remainingFact}${stateNotice}<section class="bj05-section bj05-pick-lot-group" data-ds-component="VSection">${ds24SectionTitle("Lấy theo lô",`${line.allocations.length} lô`)}<div class="ds24-list-stack bj05-pick-lot-list">${rows}</div></section><p class="bj05-pick-note" data-ds-component="VText">Chọn từng lô để cập nhật lượng đã lấy. Tồn vật lý chỉ giảm sau khi xác nhận bàn giao.</p>${bj05PickEditorSheet(line,allocation)}${bj05OverrideSheet(line,allocation)}`;
  return appShell({title:"Chi tiết lấy hàng",body,actions:primaryFooter("Lưu lượng đã lấy",'data-io05-action="save-pick"',invalid||hasCorrection)});
}
function render028BJ05(state){
  if(state==="PERMISSION_DENIED") return appShell({title:"Rà soát bàn giao",body:deniedBody(),centered:true});
  const order=io05CurrentOrder();const context=ds24InfoGroup('Thông tin đơn',`${ds24InfoRow('Đơn',order.id)}${ds24InfoRow('Khách hàng',order.customer)}${ds24InfoRow('Kho',order.warehouse)}`,'bj05-context');
  if(state==="SOURCE_CHANGED") return appShell({title:"Rà soát bàn giao",body:`${vBanner("warning","Thông tin lấy hàng đã thay đổi","Không thể dùng bản rà soát hiện tại. Hãy xem lại hàng cần lấy đã được cập nhật.")}${context}`,actions:primaryFooter("Xem hàng cần lấy đã cập nhật",'data-io05-action="back-to-pick"')});
  io05SyncHandover();const partial=state==="PARTIAL_ALLOWED"||order.partialHandoverAllowed;const blocked=state==="PARTIAL_BLOCKED";const pickedRows=io05AllAllocations(order).filter(({allocation})=>io05AllocationRemainingPicked(allocation)>0&&!io05CorrectionPending(allocation));
  const byLine=new Map();pickedRows.forEach(({line,allocation})=>{if(!byLine.has(line.id))byLine.set(line.id,{line,allocations:[]});byLine.get(line.id).allocations.push(allocation);});
  const lines=[...byLine.values()].map(({line,allocations})=>{const allocationRows=allocations.map(a=>{const available=io05AllocationRemainingPicked(a);const qty=Number(io05HandoverByAllocation[a.id]??available);const label=a.lot?`Lô ${a.lot}`:'Không theo lô';const step=Number(line.quantityStep||1);const control=partial&&!blocked?ds24TextField('Lượng thực giao',qty,`data-io05-handover-allocation="${escapeAttribute(a.id)}" type="number" min="0" max="${available}" step="${step}" inputmode="decimal" aria-label="Lượng thực giao ${escapeAttribute(label)}"`,`Tối đa ${available} ${line.uom}`):'';return `<div class="bj05-handover-allocation">${ds24KeyValueRow(label,`${available} ${line.uom}`)}${control}</div>`;}).join('');const productSummary=ds24ContextStatusRow({title:line.name,subtitle:`${line.code} · ${line.uom}`,label:'Đã lấy',tone:'Success',leading:'package'});return `<div class="bj05-handover-product ds24-grouped-subgroup">${productSummary}<div class="bj05-handover-allocation-list">${allocationRows}</div></div>`;}).join('');
  const summary=`<section class="bj05-summary" data-io05-handover-summary>${ds24KeyValueRow('Trong lần này',`${io05HandoverProductCount()} dòng hàng`,true,'data-io05-summary-in-this')}${ds24KeyValueRow('Chưa hoàn tất',`${io05RemainingProductCountAfterHandover()} dòng hàng`,false,'data-io05-summary-remaining')}</section>`;const banner=blocked?vBanner("error","Đơn này yêu cầu giao đủ","Chưa thể bàn giao một phần. Phần thiếu phải được đơn bán xử lý trước."):"";const collection=ds24GroupedCollection(lines,"bj05-handover-list bj05-grouped-collection bj05-grouped-collection--handover","DS v2 / List Row,DS v2 / Key-value Row,VTextField");const content=pickedRows.length?`<section class="bj05-section">${ds24SectionTitle("Xác nhận hàng đã giao",partial&&!blocked?"Nhập lượng thực tế theo từng lô":"Đối chiếu theo lượng đã lấy")}${collection}</section>`:ioEmpty("Chưa có hàng đã lấy","Quay lại Hàng cần lấy để xác nhận lượng đã lấy trước khi bàn giao.");const body=`${banner}${context}<section class="bj05-section">${ds24SectionTitle("Bàn giao lần này")}${summary}</section>${content}<p class="field-error bj05-field-error" data-io05-handover-error hidden></p><p class="bj05-business-note" data-ds-component="VText">Xác nhận khi hàng đã giao thực tế. Tồn vật lý chỉ giảm sau bước này.</p>`;
  return appShell({title:"Rà soát bàn giao",body,actions:primaryFooter("Xác nhận đã bàn giao",'data-io05-action="confirm-handover"',blocked||io05HandoverInvalid()||io05HandoverTotal()<=0)});
}
function render029BJ05(state){
  if (["UNKNOWN", "COMMIT_UNKNOWN"].includes(state)) {
    const o = io05CurrentOrder(); io05MarkUnknown(o); o.unknownLocked = true;
    const operation = o.operationId || o.id;
    const scope = `${o.customer} · ${o.warehouse}`;
    const body = ioResult("Kết quả chưa xác định", "Không gửi lại bàn giao. Giữ nguyên đúng lần xử lý này và chuyển sang xác minh trước khi cho phép lấy/bàn giao lại.", [["Nghiệp vụ", operation], ["Phạm vi", scope], ["Trạng thái", "Đang xác minh bàn giao"]], "warning");
    const attrs = `data-v350-action="handoff-unknown" data-source-flow="UIF-05" data-operation="${escapeAttribute(operation)}" data-scope="${escapeAttribute(scope)}"`;
    return appShell({ title: "Xác minh kết quả", body, actions: primaryFooter("Chuyển sang xác minh", attrs), centered: true, back: false });
  }
  const order=io05CurrentOrder();const r=io05LastResult;const orderId=r?.orderId||io05SelectedOrderId;const customer=r?.customer||order.customer;

  if(state==="REJECTED_EXECUTION") return appShell({title:"Kết quả bàn giao",body:ds24Result("Chưa thể bàn giao","Dữ liệu hiện hành đã thay đổi nên chưa ghi giảm tồn. Hãy xem lại hàng cần lấy trước khi xác nhận lần nữa.",[["Đơn",orderId],["Tồn vật lý","Không thay đổi"]],"warning"),centered:true,back:false,actions:primaryFooter("Xem hàng cần lấy đã cập nhật",'data-io05-action="back-to-pick"')});
  if(state==="PERMISSION_DENIED") return appShell({title:"Kết quả bàn giao",body:ds24Result("Không có quyền bàn giao","Tồn kho không thay đổi. Liên hệ người có quyền phù hợp nếu cần tiếp tục.",[["Đơn",orderId],["Tồn vật lý","Không thay đổi"]],"danger"),centered:true,back:false,actions:primaryFooter("Về danh sách đơn cần lấy",'data-io05-action="result-to-queue"')});
  const partial=state==="PARTIAL_COMPLETED"||(r&&!r.full);const title=partial?"Đã bàn giao một phần":"Đã bàn giao toàn bộ";const desc=partial?"Đã ghi giảm tồn theo đúng lượng thực bàn giao. Phần còn lại tiếp tục ở đơn này.":"Tồn vật lý đã giảm theo đúng lượng và lô thực tế bàn giao.";const summary=ds24Result(title,desc,[["Đơn",orderId],["Khách hàng",customer],["Bàn giao lúc",r?.confirmedAt||"—"]],"success");
  return appShell({title:"Kết quả bàn giao",body:`${summary}${bj05ResultDetails(r)}`,centered:false,back:false,actions:primaryFooter(partial?"Tiếp tục phần còn lại":"Về danh sách đơn cần lấy",partial?'data-io05-action="continue-remaining"':'data-io05-action="result-to-queue"')});
}

onScreenEnter["UIF-05:SCR-028"] = () => { const o = io05CurrentOrder(); o.reviewSourceVersion = o.sourceVersion; };

Object.assign(renderers, {
  "SCR-025": render025BJ05,
  "SCR-026": render026BJ05,
  "SCR-027": render027BJ05,
  "SCR-028": render028BJ05,
  "SCR-029": render029BJ05,
});
ownedFlows.add("UIF-05");

document.addEventListener("input", (event) => {
  if (activeFlowId === "UIF-05" && event.target.matches("[data-io05-search]")) { io05Query = event.target.value; ioFilterRows("io05", io05Query); return; }
  if (activeFlowId === "UIF-05" && event.target.matches("[data-io05-picked-allocation]")) { updateIO05AllocationValidation(event.target); return; }
  if (activeFlowId === "UIF-05" && event.target.matches("[data-io05-handover-allocation]")) { updateIO05HandoverValidation(event.target); return; }
  if (activeFlowId === "UIF-05" && event.target.matches("[data-io05-override-reason]")) { io05OverrideReason = event.target.value; const b = document.querySelector('[data-io05-action="confirm-lot-override"]'); if (b) b.disabled = !io05OverrideReason.trim() || !io05OverrideLot; return; }
  if (activeFlowId === "UIF-05" && event.target.matches("[data-io05-pick-draft]")) { io05PickDraft = event.target.value; const a = io05CurrentAllocation(); const b = document.querySelector('[data-io05-action="update-pick-allocation"]'); if (b) b.disabled = Number(io05PickDraft) < Number(a?.consumedQty || 0) || Number(io05PickDraft) > Number(a?.allocatedQty || 0); return; }
});

document.addEventListener("click", (event) => {
  if (activeFlowId !== "UIF-05") return;
  const f5 = event.target.closest("[data-io05-filter]"); if (f5) { event.preventDefault(); io05QueueFilter = f5.dataset.io05Filter; return renderAppScreen(); }
  const o5 = event.target.closest("[data-io05-order]"); if (o5) { event.preventDefault(); io05SelectedOrderId = o5.dataset.io05Order; const order = io05CurrentOrder(); if (order.queue === "WAITING" || order.queue === "VERIFYING") return; io05ActiveLineId = order.lines?.[0]?.id || ""; io05ActiveAllocationId = order.lines?.[0]?.allocations?.[0]?.id || ""; io05OverrideOpen = false; io05ResetHandover(order); stateByScreen["SCR-026"] = "READY"; return navigate("SCR-026"); }
  const l5 = event.target.closest("[data-io05-line]"); if (l5 && !l5.disabled) { event.preventDefault(); io05ActiveLineId = l5.dataset.io05Line; const line = io05CurrentLines().find((l) => l.id === io05ActiveLineId); io05ActiveAllocationId = line?.allocations[0]?.id || ""; return navigate("SCR-027"); }
  const pickAllocation = event.target.closest("[data-io05-pick-allocation]"); if (pickAllocation) { event.preventDefault(); io05ActiveAllocationId = pickAllocation.dataset.io05PickAllocation; const a = io05CurrentAllocation(); io05PickDraft = String(Number(a?.pickedQty || 0)); io05PickEditorOpen = true; return renderAppScreen(); }
  if (event.target.matches("[data-io05-pick-editor-backdrop]")) { event.preventDefault(); io05PickEditorOpen = false; io05PickDraft = ""; return renderAppScreen(); }
  const openOverride = event.target.closest("[data-io05-open-override]"); if (openOverride) { event.preventDefault(); io05ActiveAllocationId = openOverride.dataset.io05OpenOverride; io05PickEditorOpen = false; io05OverrideOpen = true; io05OverrideLot = ""; io05OverrideReason = ""; return renderAppScreen(); }
  if (event.target.matches("[data-io05-override-backdrop]")) { event.preventDefault(); io05OverrideOpen = false; return renderAppScreen(); }
  const selectLot = event.target.closest("[data-io05-select-lot]"); if (selectLot) { event.preventDefault(); io05OverrideLot = selectLot.dataset.io05SelectLot; return renderAppScreen(); }

  const a = event.target.closest("[data-io05-action]"); if (!a) return;
  event.preventDefault(); event.stopPropagation();
  const k = a.dataset.io05Action;
  if (k === "review-handover") { io05ResetHandover(); stateByScreen["SCR-028"] = io05CurrentOrder().partialHandoverAllowed ? "PARTIAL_ALLOWED" : "READY"; return navigate("SCR-028"); }
  if (k === "update-pick-allocation") { const a = io05CurrentAllocation(); if (!a || Number(io05PickDraft) < Number(a.consumedQty || 0) || Number(io05PickDraft) > Number(a.allocatedQty || 0)) return; a.pickedQty = Math.max(Number(a.consumedQty || 0), Number(io05PickDraft) || 0); io05HandoverByAllocation[a.id] = io05AllocationRemainingPicked(a); io05PickEditorOpen = false; io05PickDraft = ""; return renderAppScreen(); }
  if (k === "close-lot-override") { io05OverrideOpen = false; return renderAppScreen(); }
  if (k === "confirm-lot-override") { if (!io05OverrideReason.trim() || !io05OverrideLot) return; const allocation = io05CurrentAllocation(); const line = io05CurrentLine(); if (allocation && line && Number(allocation.consumedQty || 0) <= 0) { const oldLot = allocation.lot, oldPicked = io05AllocationRemainingPicked(allocation); allocation.lot = io05OverrideLot; allocation.overrideReason = io05OverrideReason; if (oldPicked > 0) { allocation.pickedQty = Number(allocation.consumedQty || 0); allocation.physicalCorrection = { kind: "MANUAL", status: "PENDING", oldLot, returnQty: oldPicked, newLot: io05OverrideLot, repickQty: oldPicked, actor: null, confirmedAt: null }; } io05HandoverByAllocation[allocation.id] = 0; const order = io05CurrentOrder(); order.allocationVersion = Number(order.allocationVersion || 0) + 1; } io05OverrideOpen = false; renderAppScreen(); return showToast("Đã cập nhật lô lấy hàng", "success"); }
  if (k === "confirm-physical-correction") { const a = io05CurrentAllocation(); if (!a || !io05CorrectionPending(a) || Number(a.pickedQty || 0) < Number(a.physicalCorrection.repickQty || 0)) return; a.physicalCorrection = { ...a.physicalCorrection, status: "CONFIRMED", actor: IO05_ACTOR.name, actorId: IO05_ACTOR.id, confirmedAt: "16/09/2026 13:06" }; return renderAppScreen(); }
  if (k === "save-pick") { io05PickEditorOpen = false; io05PickDraft = ""; const line = io05CurrentLine(); if (!line || line.allocations.some((a) => Number(a.pickedQty || 0) > Number(a.allocatedQty || 0)) || line.allocations.some((a) => io05CorrectionPending(a))) return; io05ResetHandover(); return navigate("SCR-026"); }
  if (k === "back-to-pick") { stateByScreen["SCR-026"] = "READY"; return navigate("SCR-026"); }
  if (k === "result-to-queue") { io05QueueFilter = "ALL"; io05Query = ""; return navigate("SCR-025"); }
  if (k === "continue-remaining") { stateByScreen["SCR-026"] = "READY"; return navigate("SCR-026"); }
  if (k === "confirm-handover") { if (io05HandoverInvalid() || io05HandoverTotal() <= 0) return; const result = io05ApplyHandover(); if (!result) return; stateByScreen["SCR-029"] = result.full ? "COMPLETED" : "PARTIAL_COMPLETED"; return navigate("SCR-029"); }
});
