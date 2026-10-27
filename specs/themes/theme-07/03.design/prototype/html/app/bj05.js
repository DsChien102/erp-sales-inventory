/* BJ-05 — Lấy hàng và bàn giao đơn (UIF-05). Màn: SCR-025, SCR-026, SCR-028, SCR-029 (SCR-027 đã gộp vào SCR-026 từ v5.11.0).
 *
 * Thiết kế lại (T7-P BJ-04 / BJ-05, 2026-10-24, v5.11.0): mọi fixture, trạng thái, helper io05*, hàm dựng và xử lý sự kiện
 * của BJ-05 nằm ở đây; sửa BJ-05: sửa thẳng file này.
 * Dùng từ khuôn (shared-patterns.js): k1Loading, k1Denied, k1Empty, k1Stale, k1ExitAttr (K1); k3Unknown (K3); k4Result,
 * k4ReasonFooter (K4); k6TaskList (K6, dựng ở đây); k7Split, k7Table, k7EditCell (K7); dsSegmented, dsChoiceRow.
 * Dùng chung từ app/core.js: appShell, ds24*, vBanner, esc, escapeAttribute, navigate, renderAppScreen, showToast, onScreenEnter.
 * Handoff UNKNOWN: đăng ký onUnknownHandoff["UIF-05"]; nút data-k3-action="handoff" do k3Unknown dựng → bj17.js.
 * Trạng thái đặt từ bộ kiểm (đổi trạng thái màn) dựng lại đơn từ bản gốc: xem io05Seed.
 */

const IO05_ACTOR={id:"USR-WH-001",name:"Nguyễn Văn An"};
const io05Orders=[
  {id:"SO-260827-21",customer:"Đại lý An Phú",warehouse:"Kho chính",queue:"ACTIONABLE",partialHandoverAllowed:true,partialPolicyVersion:"FUL-POL-v3",fulfillmentVersion:7,sourceVersion:7,allocationSetId:"AS-21",allocationVersion:4,closed:false,status:"Cần lấy hàng",shortage:0,operationId:"IO-HO-SO26082721-01",lines:[
    {id:"PK-21-01",name:"Nobivac DHPPi",code:"SP-000184",uom:"hộp",baseUom:"hộp",conversionToBase:1,conversionVersion:"UOM-SP000184-v2",quantityStep:1,requestedQty:20,deliveredQty:0,allocations:[
      {id:"AL-21-01",allocatedQty:4,allocatedBaseQty:4,pickedQty:4,consumedQty:0,suggestedLot:"DH2507",lot:"DH2507",overrideReason:"",physicalCorrection:null,eligibleLots:[
        {code:"DH2507",expiryDisplay:"30/11/2026",expiryPrecision:"DAY",pickableQty:4,asOf:"27/08/2026 09:41",snapshotVersion:"LOT-Q-v12",recommended:true},
        {code:"DH2509",expiryDisplay:"30/09/2026",expiryPrecision:"DAY",pickableQty:18,asOf:"27/08/2026 09:41",snapshotVersion:"LOT-Q-v12",recommended:false},
        {code:"DH2511",expiryDisplay:"2027",expiryPrecision:"YEAR",pickableQty:22,asOf:"27/08/2026 09:41",snapshotVersion:"LOT-Q-v12",recommended:false}
      ]},
      {id:"AL-21-02",allocatedQty:16,allocatedBaseQty:16,pickedQty:8,consumedQty:0,suggestedLot:"DH2509",lot:"DH2509",overrideReason:"",physicalCorrection:null,eligibleLots:[
        {code:"DH2509",expiryDisplay:"30/09/2026",expiryPrecision:"DAY",pickableQty:18,asOf:"27/08/2026 09:41",snapshotVersion:"LOT-Q-v12",recommended:true},
        {code:"DH2511",expiryDisplay:"2027",expiryPrecision:"YEAR",pickableQty:22,asOf:"27/08/2026 09:41",snapshotVersion:"LOT-Q-v12",recommended:false}
      ]}
    ]},
    {id:"PK-21-02",name:"Găng tay khám Nitrile",code:"SP-000271",uom:"hộp",baseUom:"hộp",conversionToBase:1,conversionVersion:"UOM-SP000271-v1",quantityStep:1,requestedQty:6,deliveredQty:0,allocations:[
      {id:"AL-21-03",allocatedQty:6,allocatedBaseQty:6,pickedQty:0,consumedQty:0,suggestedLot:null,lot:null,overrideReason:"",physicalCorrection:null,eligibleLots:[]}
    ]}
  ]},
  {id:"SO-260827-22",customer:"Trang trại Phú Lợi",warehouse:"Kho chính",queue:"ACTIONABLE",partialHandoverAllowed:false,partialPolicyVersion:"FUL-POL-v3",fulfillmentVersion:2,sourceVersion:2,allocationSetId:"AS-22",allocationVersion:1,closed:false,status:"Chờ bàn giao",shortage:0,operationId:"IO-HO-SO26082722-01",lines:[
    {id:"PK-22-01",name:"Vitamin ADE",code:"SP-000099",uom:"chai",baseUom:"chai",conversionToBase:1,conversionVersion:"UOM-SP000099-v1",quantityStep:0.5,requestedQty:6,deliveredQty:0,allocations:[
      {id:"AL-22-01",allocatedQty:6,allocatedBaseQty:6,pickedQty:6,consumedQty:0,suggestedLot:null,lot:null,overrideReason:"",physicalCorrection:null,eligibleLots:[]}
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
let io05ActiveAllocationId="AL-21-01", io05OverrideOpen=false, io05OverrideLot="", io05OverrideReason="";
let io05PickEditorOpen=false, io05PickDraft="", io05ResultSheetOpen=false, io05Recipient="COUNTER";
let io05HandoverByAllocation={}, io05LastResult=null, io05StaleAppliedForOrder={}, io05PickedError={};
io05Orders.forEach((o) => { o.sourceVersion ??= 1; o.reviewSourceVersion ??= null; o.unknownLocked ??= false; });
const io05InitialOrders=structuredClone(io05Orders);
const IO05_RECIPIENTS=[["COUNTER","Khách nhận tại quầy"],["CARRIER","Đơn vị vận chuyển"]];
const IO05_DENIED={what:"lấy và bàn giao hàng",next:"Liên hệ chủ cửa hàng để được cấp quyền."};
function io05CurrentOrder(){return io05Orders.find(o=>o.id===io05SelectedOrderId)||io05Orders.find(o=>!o.closed)||io05Orders[0];}
function io05CurrentLines(){return io05CurrentOrder()?.lines||[];}
function io05LineRequested(line){return Number(line?.requestedQty||0);}
function io05LineDelivered(line){return Number(line?.deliveredQty||0);}
function io05LineRemaining(line){return Math.max(0,io05LineRequested(line)-io05LineDelivered(line));}
function io05AllocationRemainingPicked(a){return Math.max(0,Number(a?.pickedQty||0)-Number(a?.consumedQty||0));}
function io05AllocationNeed(a){return Math.max(0,Number(a?.allocatedQty||0)-Number(a?.consumedQty||0));}
function io05LinePicked(line){return (line.allocations||[]).reduce((sum,a)=>sum+io05AllocationRemainingPicked(a),0);}
function io05LinePickedCumulative(line){return (line.allocations||[]).reduce((sum,a)=>sum+Number(a.pickedQty||0),0);}
function io05LineAllocated(line){return (line.allocations||[]).reduce((sum,a)=>sum+Number(a.allocatedQty||0),0);}
function io05OrderPickedTotal(order=io05CurrentOrder()){return (order?.lines||[]).reduce((s,l)=>s+io05LinePicked(l),0);}
function io05OrderRemainingTotal(order=io05CurrentOrder()){return (order?.lines||[]).reduce((s,l)=>s+io05LineRemaining(l),0);}
function io05LineStatus(line){const ready=io05LinePicked(line),remaining=io05LineRemaining(line);if(remaining<=0)return {label:"Đã bàn giao",tone:"success"};return ready<=0?{label:"Chưa lấy",tone:"neutral"}:ready<remaining?{label:"Đã lấy một phần",tone:"warning"}:{label:"Đã lấy đủ",tone:"success"};}
// Nhóm hàng đợi: PICK (chưa lấy / đang lấy) · HANDOVER (đã lấy đủ phần cần giao) · WAITING (chờ đơn bán) · VERIFYING (đang xác minh bàn giao).
function io05Queue(order){
  if(order.queue==="VERIFYING")return "VERIFYING";
  if(order.queue==="WAITING")return "WAITING";
  const picked=io05OrderPickedTotal(order), remaining=io05OrderRemainingTotal(order);
  return remaining>0&&picked>=remaining?"HANDOVER":"PICK";
}
function io05OrderStatus(order){
  if(order.closed)return {label:"Đã bàn giao",tone:"success"};
  const q=io05Queue(order);
  if(q==="VERIFYING")return {label:"Đang xác minh bàn giao",tone:"warning"};
  if(q==="WAITING")return {label:"Chờ đơn bán",tone:"warning"};
  if(q==="HANDOVER")return {label:"Chờ bàn giao",tone:"info"};
  return io05OrderPickedTotal(order)<=0?{label:"Cần lấy hàng",tone:"neutral"}:{label:"Đang lấy hàng",tone:"info"};
}
function io05VisibleOrders(){return io05Orders.filter(o=>!o.closed);}
function io05ActiveLines(order){return (order?.lines||[]).filter(l=>io05LineRemaining(l)>0);}
function io05FullyPickedLines(order){return io05ActiveLines(order).filter(l=>io05LinePicked(l)>=io05LineRemaining(l));}
function io05NextActionableOrder(){const last=io05LastResult?.orderId;return io05VisibleOrders().find(o=>o.id!==last&&io05Queue(o)==="PICK")||null;}
function io05AllAllocations(order=io05CurrentOrder()){return (order?.lines||[]).flatMap(l=>(l.allocations||[]).map(a=>({line:l,allocation:a})));}
function io05FindAllocation(id,order=io05CurrentOrder()){return io05AllAllocations(order).find(x=>x.allocation.id===id)||null;}
function io05ResetHandover(order=io05CurrentOrder()){io05HandoverByAllocation={};io05AllAllocations(order).forEach(({allocation})=>{const available=io05AllocationRemainingPicked(allocation);if(available>0)io05HandoverByAllocation[allocation.id]=available;});}
function io05SyncHandover(){io05AllAllocations().forEach(({allocation})=>{const available=io05AllocationRemainingPicked(allocation);if(available>0&&io05HandoverByAllocation[allocation.id]==null)io05HandoverByAllocation[allocation.id]=available;});}
io05ResetHandover();
function io05CurrentAllocation(){return io05FindAllocation(io05ActiveAllocationId)?.allocation||null;}
function io05CorrectionPending(a){return Boolean(a?.physicalCorrection&&a.physicalCorrection.status!=="CONFIRMED");}
function io05AnyCorrectionPending(order=io05CurrentOrder()){return io05AllAllocations(order).some(({allocation})=>io05CorrectionPending(allocation));}
function io05PartialAllowed(order,state){return Boolean(order?.partialHandoverAllowed)&&state!=="PARTIAL_BLOCKED";}
function io05CanReview(){const order=io05CurrentOrder();const q=order?io05Queue(order):"WAITING";if(q==="WAITING"||q==="VERIFYING"||io05OrderPickedTotal(order)<=0||io05AnyCorrectionPending(order))return false;return order.partialHandoverAllowed?true:io05FullyPickedLines(order).length>=io05ActiveLines(order).length;}
// Lý do hiện trên chân màn 026 khi "Rà soát bàn giao" tắt.
function io05ReviewReason(){
  const order=io05CurrentOrder();if(io05CanReview())return "";
  if(io05OrderPickedTotal(order)<=0)return "Lấy ít nhất một mặt hàng";
  if(io05AnyCorrectionPending(order))return "Xác nhận điều chỉnh lô trước khi bàn giao";
  return io05RequireFullReason(order);
}
function io05RequireFullReason(order){return `Đơn này yêu cầu giao đủ · còn ${io05ActiveLines(order).length-io05FullyPickedLines(order).length} mặt hàng chưa lấy đủ`;}
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
function io05LotLabel(a){return a?.lot?`Lô ${a.lot}`:"Không theo lô";}
function io05RecipientLabel(key){return (IO05_RECIPIENTS.find(([k])=>k===key)||IO05_RECIPIENTS[0])[1];}
function io05ApplyStaleRecovery(){
  const order=io05CurrentOrder(); if(!order||order.id!=="SO-260827-21"||io05StaleAppliedForOrder[order.id])return;
  const line=order.lines.find(l=>l.id==="PK-21-01"); const a=line?.allocations.find(x=>x.id==="AL-21-01"); if(!a)return;
  const oldLot=a.lot, unconsumed=io05AllocationRemainingPicked(a); a.lot="DH2511"; a.pickedQty=Number(a.consumedQty||0);
  if(unconsumed>0)a.physicalCorrection={kind:"STALE",status:"PENDING",oldLot,returnQty:unconsumed,newLot:"DH2511",repickQty:unconsumed,actor:null,confirmedAt:null};
  order.allocationVersion=Number(order.allocationVersion||0)+1; io05StaleAppliedForOrder[order.id]=true;io05ResetHandover(order);
}
function io05CorrectionText(line,a){const c=a?.physicalCorrection;if(!c||c.status==="CONFIRMED")return "";return `Trả ${c.returnQty} ${line.uom} lô ${c.oldLot}; lấy lại ${c.repickQty} ${line.uom} lô ${c.newLot}.`;}
function io05MarkUnknown(order=io05CurrentOrder()){if(!order)return;order.queue="VERIFYING";order.status="Đang xác minh bàn giao";order.verificationOperationId=order.operationId;}
function io05PickFull(allocationId){
  const hit=io05FindAllocation(allocationId); if(!hit||io05CorrectionPending(hit.allocation))return false;
  const a=hit.allocation; a.pickedQty=Number(a.consumedQty||0)+io05AllocationNeed(a); io05HandoverByAllocation[a.id]=io05AllocationRemainingPicked(a); return true;
}
// "Lấy đủ tất cả" (G3-7 U4): lấy đủ mọi lô còn thiếu, bỏ qua lô đang chờ điều chỉnh hàng đang cầm.
function io05PickableAllocations(order=io05CurrentOrder()){return io05AllAllocations(order).filter(({allocation:a})=>!io05CorrectionPending(a)&&io05AllocationRemainingPicked(a)<io05AllocationNeed(a));}
function io05PickAllFull(){const ids=io05PickableAllocations().map(({allocation})=>allocation.id);ids.forEach(io05PickFull);return ids.length>0;}
function io05ApplyHandover(){
  const order=io05CurrentOrder();
  if (!order || Number(order.reviewSourceVersion ?? 0) !== Number(order.sourceVersion ?? 0)) {
    io05SetState("SCR-028", "SOURCE_CHANGED");
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
    // Bàn giao là lúc tồn vật lý giảm (và bỏ phần đang giữ cho đơn): ghi vào sổ chung.
    t7Ledger.post({ key: `UIF-05:${order.id}:${(order.handoverCount||0)+1}:${allocation.id}`, productId: line.code, lot: allocation.lot, kind: "Bàn giao hàng", doc: order.id, delta: -q, eligibleDelta: -q, reservedDelta: -q, sourceFlow: "UIF-05", opId: order.operationId });
  });
  const remaining=io05OrderRemainingTotal(order); const full=remaining<=0; const confirmedAt="16/09/2026 13:08";
  const evidence={handoverId:`HO-${order.id}-${String((order.handoverCount||0)+1).padStart(2,'0')}`,operationId:order.operationId,sourceId:order.id,sourceVersion:(order.sourceVersion??order.fulfillmentVersion),warehouse:order.warehouse,actorId:IO05_ACTOR.id,actorName:IO05_ACTOR.name,recipient:io05Recipient,confirmedAt,allocationSetId:order.allocationSetId,allocationVersion:order.allocationVersion,lines:handoverLines,evidenceHash:`sha256:${order.id}:${order.allocationVersion}:${handoverLines.length}`};
  order.handoverCount=Number(order.handoverCount||0)+1;order.lastHandoverEvidence=evidence;
  if(full){order.closed=true;order.status="Đã bàn giao";}else{order.queue="ACTIONABLE";order.status="Cần tiếp tục";}
  const result={orderId:order.id,customer:order.customer,handed,remaining,full,detail,confirmedAt,recipient:io05Recipient,actorName:IO05_ACTOR.name,evidence};io05LastResult=result;io05ResetHandover(order);return result;
}

/* ---------- Trạng thái trong luồng và trạng thái đặt từ bộ kiểm ----------
 * Đi bằng nút trong màn thì đặt trạng thái qua io05SetState (đánh dấu "đã biết"). Trạng thái khác với dấu đã biết nghĩa là
 * bộ kiểm / đường dẫn đặt từ ngoài: dựng lại đơn từ bản gốc rồi chuẩn bị đúng đơn cho trạng thái đó, để ca này không
 * mang dữ liệu của ca trước (vd. lô đã đổi, bàn giao đã ghi). */
const io05ExpectedState={};
function io05SetState(screenId,state){stateByScreen[screenId]=state;io05ExpectedState[screenId]=state;}
function io05ResetUi(){io05OverrideOpen=false;io05OverrideLot="";io05OverrideReason="";io05PickEditorOpen=false;io05PickDraft="";io05ResultSheetOpen=false;io05PickedError={};}
function io05Restore(){
  io05Orders.splice(0,io05Orders.length,...structuredClone(io05InitialOrders));
  io05StaleAppliedForOrder={};io05LastResult=null;io05Recipient="COUNTER";io05ResetUi();
}
function io05Seed(screenId,state){
  if(io05ExpectedState[screenId]===state)return;
  io05ExpectedState[screenId]=state;
  io05Restore();
  io05SelectedOrderId="SO-260827-21";
  if(screenId==="SCR-025"){io05QueueFilter="ALL";io05Query=state==="FILTER_EMPTY"?"zzz":"";return;}
  if(screenId==="SCR-026"){if(state==="SHORTAGE")io05SelectedOrderId="SO-260827-24";if(state==="STALE_RECOVERED")io05ApplyStaleRecovery();return;}
  if(screenId==="SCR-028"){if(state==="READY")io05SelectedOrderId="SO-260827-22";io05ResetHandover();const o=io05CurrentOrder();o.reviewSourceVersion=state==="SOURCE_CHANGED"?Number(o.sourceVersion||0)-1:o.sourceVersion;return;}
  if(screenId==="SCR-029")io05DemoResult(state);
}
// Kết quả bàn giao mẫu cho 029 mở thẳng bằng trạng thái (chưa đi qua 028): COMPLETED = đơn giao đủ, PARTIAL_COMPLETED = giao một phần.
function io05DemoResult(state){
  if(state!=="COMPLETED"&&state!=="PARTIAL_COMPLETED"||io05LastResult)return;
  io05SelectedOrderId=state==="COMPLETED"?"SO-260827-22":"SO-260827-21";
  const o=io05CurrentOrder();o.reviewSourceVersion=o.sourceVersion;io05ResetHandover(o);io05ApplyHandover();
}

/* ---------- Dựng phần dùng chung ---------- */

function bj05DsTone(tone="neutral") {
  const t=String(tone||"neutral").toLowerCase();
  return t==="success"?"Success":t==="warning"?"Warning":t==="danger"?"Danger":t==="info"?"Info":"Neutral";
}
function bj05Shell(opts){return appShell({...opts,extraClass:"k7-wide"});}
function bj05Denied(title,back=true){return bj05Shell({title,body:k1Denied({...IO05_DENIED,exitAttr:k1ExitAttr("SCR-025")}),centered:true,back});}
function bj05Loading(title,subtitle,blocks,back=true){return bj05Shell({title,subtitle,body:k1Loading({blocks}),back});}
function bj05TextArea(label,value,attrs="",helper="") {
  return `<label class="bj05-textarea" data-ds-component="VTextarea" data-figma-node="522:7212" data-ds-prop-state="Filled"><span class="vet45-text-style-8">${esc(label)}</span><textarea class="bj05-textarea__control vet45-text-style-6" rows="3" ${attrs}>${esc(value)}</textarea>${helper?`<small class="vet45-text-style-11">${esc(helper)}</small>`:""}</label>`;
}
function bj05Progress(done,total){
  if(!total)return "";
  return `<div class="bj02-progress-block bj05-progress" data-ds-component="VProgress"><div class="bj02-progress" role="progressbar" aria-label="Tiến độ lấy hàng" aria-valuemin="0" aria-valuemax="${total}" aria-valuenow="${done}"><span style="width:${Math.round(done/total*100)}%"></span></div><small>Đã lấy đủ ${done}/${total} mặt hàng</small></div>`;
}
function bj05Link(label,attrs=""){return `<button class="k7-row-link bj05-link" type="button" ${attrs}>${esc(label)}</button>`;}
function bj05Button(label,attrs="",variant="secondary"){return `<button class="button button--${variant} bj05-small-button" type="button" ${attrs} data-ds-component="VButton" data-ds-prop-variant="VButtonVariant.${variant}" data-ds-prop-size="VButtonSize.small">${esc(label)}</button>`;}
function bj05Facts(order,{withLink=false}={}){
  const rows=[["Khách hàng",order.customer],["Kho",order.warehouse],["Giao một phần",order.partialHandoverAllowed?"Được":"Không"]];
  return `${ac310KeyValueSurface("Tóm tắt",rows)}${withLink?bj05Link("Xem giữ hàng",'data-io05-go-reservation'):""}`;
}

/* ---------- Hộp thoại / sheet ---------- */

function bj05OverrideSheet(line,allocation) {
  if(!io05OverrideOpen||!allocation)return "";
  const alternatives=(allocation.eligibleLots||[]).filter(x=>(typeof x==='string'?x:x.code)!==allocation.lot).map(x=>typeof x==='string'?{code:x,expiry:'—',available:'—'}:x);
  const rows=alternatives.map(m=>{const selected=io05OverrideLot===m.code;return dsChoiceRow({title:`Lô ${m.code}`,subtitle:`HSD ${io05ExpiryDisplay(m)} · Có thể lấy ${m.pickableQty} ${line.uom}`,selected,attrs:`data-io05-select-lot="${escapeAttribute(m.code)}"`});}).join('');
  const desc=io05AllocationRemainingPicked(allocation)>0?`Đổi lô cần xác nhận đã trả lô cũ và lấy lại đúng lô mới trước khi bàn giao.`:`Chọn một lô đủ điều kiện trong ${io05CurrentOrder().warehouse}.`;
  const textarea=bj05TextArea('Lý do đổi lô *',io05OverrideReason,'data-io05-override-reason placeholder="Nhập lý do"','Bắt buộc để lưu vết thay đổi.');
  const ready=io05OverrideReason.trim()&&io05OverrideLot;
  return `<div class="sheet-backdrop bj05-lot-sheet-backdrop" data-io05-override-backdrop><section class="bottom-sheet bj05-lot-sheet" data-ds-component="VBottomSheet" data-figma-node="4695:6353" data-ds-prop-show-title="true" data-ds-prop-title="Chọn lô thay thế" data-composed-from="VBottomSheet,DS v2 / List Row,VTextarea,VButton" role="dialog" aria-modal="true" aria-label="Chọn lô thay thế"><div class="sheet-handle" data-ds-internal="VBottomSheet.handle"></div><div class="sheet-title" data-ds-internal="VBottomSheet.title"><h3>Chọn lô thay thế</h3></div><div class="sheet-content bj05-lot-sheet__content" data-ds-internal="VBottomSheet.content"><p class="bj05-lot-sheet__intro">${esc(desc)}</p><div class="ds-choice-list bj05-selection-list" role="radiogroup" aria-label="Lô thay thế">${rows}</div>${textarea}<button class="button button--primary bj05-lot-sheet__cta" data-io05-action="confirm-lot-override" data-ds-component="VButton" data-figma-node="521:529" data-ds-prop-hierarchy="Primary" data-ds-prop-state="${ready?'Default':'Disabled'}" data-ds-prop-size="Default" data-ds-prop-leading-icon="false" type="button" ${ready?'':'disabled'}>Dùng lô này</button></div></section></div>`;
}
function bj05PickEditorSheet(line,allocation){
  if(!io05PickEditorOpen||!allocation)return "";
  const meta=allocation.lot?io05EligibleLotMeta(allocation,allocation.lot):null;const need=io05AllocationNeed(allocation);const step=Number(line.quantityStep||1);const helper=`Tối đa ${need} ${line.uom}`;
  const canChange=Number(allocation.consumedQty||0)<=0&&allocation.suggestedLot&&allocation.eligibleLots?.some(x=>(typeof x==='string'?x:x.code)!==allocation.lot);
  const invalid=io05PickDraft===""||Number(io05PickDraft)<0||Number(io05PickDraft)>need;
  return `<div class="sheet-backdrop bj05-pick-editor-backdrop" data-io05-pick-editor-backdrop><section class="bottom-sheet bj05-pick-editor-sheet" data-ds-component="VBottomSheet" data-figma-node="4695:6353" role="dialog" aria-modal="true" aria-label="${escapeAttribute(io05LotLabel(allocation))}"><div class="sheet-handle"></div><div class="sheet-title"><h3>${esc(io05LotLabel(allocation))}</h3></div><div class="sheet-content bj05-pick-editor-sheet__content"><p class="bj05-pick-editor-sheet__meta">${[meta?`HSD ${io05ExpiryDisplay(meta)}`:"",`Cần lấy ${need} ${line.uom}`].filter(Boolean).map(esc).join(' · ')}</p>${ds24TextField('Đã lấy',io05PickDraft,`data-io05-pick-draft type="number" min="0" max="${need}" step="${step}" inputmode="decimal"`,helper)}${canChange?`<button class="button button--secondary bj05-pick-editor-sheet__change" data-io05-open-override="${escapeAttribute(allocation.id)}" type="button" data-ds-component="VButton">Đổi lô</button>`:""}<button class="button button--primary bj05-pick-editor-sheet__save" data-io05-action="update-pick-allocation" type="button" data-ds-component="VButton" ${invalid?'disabled':''}>Cập nhật</button></div></section></div>`;
}
function bj05ResultSheet(result){
  if(!io05ResultSheetOpen||!result)return "";
  const actual=io05ResultRows(result);
  const actualRows=actual.map(x=>ds24ListRow({title:x.product,subtitle:`${x.code} · ${x.lot?`Lô ${x.lot}`:'Không theo lô'}`,trailing:`<strong class="bj05-row-quantity">${x.qty} ${esc(x.uom)}</strong>`,leading:null,type:"Status",interactive:false,density:"Compact"})).join('');
  const remaining=io05ActiveLines(io05Orders.find(o=>o.id===result.orderId));
  const remainingRows=remaining.map(l=>ds24ListRow({title:l.name,subtitle:`${l.code} · Còn cần lấy`,trailing:`<strong class="bj05-row-quantity">${io05LineRemaining(l)} ${esc(l.uom)}</strong>`,leading:null,type:"Status",interactive:false,density:"Compact"})).join('');
  const body=`${actualRows?`<section class="bj05-section">${ds24SectionTitle('Bàn giao thực tế',`${actual.length} phần hàng`)}<div class="ds24-list-stack">${actualRows}</div></section>`:''}${remainingRows?`<section class="bj05-section">${ds24SectionTitle('Còn lại',`${remaining.length} dòng hàng`)}<div class="ds24-list-stack">${remainingRows}</div></section>`:''}<button class="button button--primary button--full" type="button" data-io05-sheet-close data-ds-component="VButton">Đóng</button>`;
  return ds24Sheet({title:`Chi tiết ${actual.length+remaining.length} dòng hàng`,body,attrs:"data-io05-sheet-close-backdrop"});
}

/* ---------- SCR-025 Đơn cần lấy hàng (K6) ---------- */

function io05OrderModel(o){
  const st=io05OrderStatus(o), q=io05Queue(o), active=io05ActiveLines(o), done=io05FullyPickedLines(o).length;
  const disabled=q==="WAITING"||q==="VERIFYING";
  const link=`<button class="k7-row-link" type="button" ${disabled?"disabled":""}>${esc(o.id)}</button>`;
  return {order:o,queue:q,title:o.id,subtitle:`${o.customer} · ${active.length} mặt hàng`,status:{label:st.label,tone:bj05DsTone(st.tone)},statusHtml:ds24Badge(st.label,bj05DsTone(st.tone)),idHtml:link,customer:o.customer,count:q==="WAITING"?'<span class="k7-muted">—</span>':`${done}/${active.length} mặt hàng`,total:active.length,disabled,target:q==="HANDOVER"?"SCR-028":"SCR-026"};
}
function render025BJ05(state){
  const title="Đơn cần lấy hàng",subtitle="Từ đơn bán đã sẵn sàng xuất kho";
  io05Seed("SCR-025",state);
  if(state==="PERMISSION_DENIED")return bj05Denied(title,false);
  if(state==="LOADING")return bj05Loading(title,subtitle,["search","row","row","row"],false);
  const source=io05VisibleOrders().map(io05OrderModel);
  const count=(key)=>key==="ALL"?source.length:source.filter(m=>m.queue===key).length;
  const items=[["ALL","Tất cả"],["PICK","Cần lấy"],["HANDOVER","Chờ bàn giao"],["WAITING","Đang chờ"]].map(([k,l])=>[k,l,count(k)]);
  const rows=source.filter(m=>(io05QueueFilter==="ALL"||m.queue===io05QueueFilter)&&ioMatchesSearch(io05Query,`${m.order.id} ${m.order.customer}`));
  const columns=[{key:"idHtml",label:"Đơn",html:true},{key:"customer",label:"Khách hàng"},{key:"count",label:"Đã lấy",html:true,align:"end",mono:true},{key:"statusHtml",label:"Tình trạng",html:true}];
  const body=k6TaskList({
    search:{value:io05Query,attr:"data-io05-search",placeholder:"Tìm mã đơn hoặc khách hàng"},
    filters:{items,selected:io05QueueFilter,attrName:"data-io05-filter"},
    columns,rows:state==="EMPTY"?[]:rows,total:state==="EMPTY"?0:source.length,
    rowAttr:(m)=>`data-io05-order="${escapeAttribute(m.order.id)}" data-io05-target="${m.target}" data-io05-search-text="${escapeAttribute(ioNormalizeSearch(`${m.order.id} ${m.order.customer}`))}"`,
    empty:{title:"Chưa có đơn cần xử lý",description:"Các đơn cần lấy hoặc đang chờ đơn bán xử lý sẽ xuất hiện tại đây."},
    filterEmpty:{title:"Không tìm thấy đơn phù hợp",description:"Thử mã đơn, tên khách hàng hoặc đổi bộ lọc.",actionLabel:"Xem tất cả",actionAttr:'data-io05-action="clear-filter"'},
    filterEmptyAttr:"data-io05-filter-empty"
  });
  return bj05Shell({title,subtitle,body,back:false,centered:state==="EMPTY"});
}

/* ---------- SCR-026 Hàng cần lấy (gộp SCR-027) ---------- */

function io05LotRows(order){
  const rows=[];
  (order.lines||[]).forEach(line=>{
    const allocs=(line.allocations||[]).filter(a=>io05AllocationNeed(a)>0);
    if(io05LineRemaining(line)<=0||!allocs.length){rows.push({kind:"done",line,first:true});return;}
    allocs.forEach((allocation,i)=>rows.push({kind:"lot",line,allocation,first:i===0}));
  });
  return rows;
}
// Bên phải một dòng lô: nút "Lấy đủ" / badge / xác nhận điều chỉnh. readOnly: đơn chờ hoặc đang xác minh.
function io05LotAction(line,a,readOnly){
  if(readOnly)return "";
  const need=io05AllocationNeed(a), picked=io05AllocationRemainingPicked(a), c=a.physicalCorrection;
  if(io05CorrectionPending(a))return picked>=Number(c.repickQty||0)?bj05Button("Xác nhận đã điều chỉnh hàng",`data-io05-action="confirm-physical-correction" data-io05-allocation="${escapeAttribute(a.id)}"`):"";
  const full=bj05Button("Lấy đủ",`data-io05-pick-full="${escapeAttribute(a.id)}" aria-label="Lấy đủ ${escapeAttribute(io05LotLabel(a))} ${escapeAttribute(line.name)}"`);
  if(picked>=need)return ds24Badge("Đã lấy đủ","Success");
  return picked<=0?full:`<span class="bj05-lot-stack">${ds24Badge("Đã lấy một phần","Warning")}${full}</span>`;
}
function io05ProductHead(line,done){
  return ds24ListRow({title:line.name,subtitle:`${line.code} · Cần ${io05LineRemaining(line)} ${line.uom}`,trailing:done?ds24Badge("Đã bàn giao","Success"):"",leading:"package",type:"Status",density:"Compact",interactive:false,extraClass:"bj05-lot-head"});
}
function io05MobileLotRow(r,readOnly){
  const head=r.first?io05ProductHead(r.line,r.kind==="done"):"";
  if(r.kind==="done")return head;
  const {line,allocation:a}=r, need=io05AllocationNeed(a), picked=io05AllocationRemainingPicked(a);
  const meta=a.lot?io05EligibleLotMeta(a,a.lot):null;
  const sub=[meta?`HSD ${io05ExpiryDisplay(meta)}`:"",`Lấy ${need} ${line.uom}`].filter(Boolean).join(" · ");
  const progress=picked>0&&picked<need?`<small class="bj05-lot__progress">Đã lấy ${picked}/${need} ${esc(line.uom)}</small>`:"";
  const correction=!readOnly&&io05CorrectionPending(a)?vBanner("warning","Cần điều chỉnh hàng đang cầm",esc(io05CorrectionText(line,a)),"bj05-lot__banner","Compact"):"";
  const copy=`<span class="ds24-list-row__copy"><strong>${esc(io05LotLabel(a))}</strong><small>${esc(sub)}</small>${progress}</span>`;
  const main=readOnly?`<span class="bj05-lot__main">${copy}</span>`:`<button class="bj05-lot__main" type="button" data-io05-pick-allocation="${escapeAttribute(a.id)}">${copy}</button>`;
  return `${head}${correction}<div class="bj05-lot ds24-list-row ds24-list-row--no-leading" data-ds-component="DS v2 / List Row" data-ds-prop-type="Status" data-ds-prop-state="Default" data-ds-prop-density="Default" data-ds-prop-leading="Hidden" data-io05-lot-row="${escapeAttribute(a.id)}">${main}<span class="bj05-lot__action">${io05LotAction(line,a,readOnly)}</span></div>`;
}
function io05WebCells(r,readOnly){
  const name=r.first?`<strong>${esc(r.line.name)}</strong><small>${esc(r.line.code)}</small>`:`<span class="k7-sr">${esc(r.line.name)}</span>`;
  if(r.kind==="done")return {product:name,lot:'<span class="k7-muted">—</span>',expiry:'<span class="k7-muted">—</span>',need:`${io05LineDelivered(r.line)} ${esc(r.line.uom)}`,picked:'',action:ds24Badge("Đã bàn giao","Success")};
  const {line,allocation:a}=r, need=io05AllocationNeed(a), picked=io05AllocationRemainingPicked(a);
  const meta=a.lot?io05EligibleLotMeta(a,a.lot):null;
  const canChange=!readOnly&&Number(a.consumedQty||0)<=0&&a.suggestedLot&&(a.eligibleLots||[]).some(x=>(typeof x==='string'?x:x.code)!==a.lot);
  const err=io05PickedError[a.id]?`Số lượng đã lấy không được vượt ${need} ${line.uom}.`:"";
  const edit=readOnly?`${picked} ${esc(line.uom)}`:k7EditCell({value:picked,attr:`data-io05-picked-allocation="${escapeAttribute(a.id)}" max="${need}" step="${Number(line.quantityStep||1)}"`,unit:line.uom,error:err,label:`Đã lấy ${io05LotLabel(a)} ${line.name}`});
  return {product:name,lot:esc(io05LotLabel(a)),expiry:meta?esc(io05ExpiryDisplay(meta)):'<span class="k7-muted">—</span>',need:`${need} ${esc(line.uom)}`,picked:edit,action:`<span class="bj05-row-actions">${io05LotAction(line,a,readOnly)}${canChange?bj05Link("Đổi lô",`data-io05-open-override="${escapeAttribute(a.id)}"`):""}</span>`};
}
function render026BJ05(state){
  const title="Hàng cần lấy";
  io05Seed("SCR-026",state);
  if(state==="PERMISSION_DENIED")return bj05Denied(title);
  const order=io05CurrentOrder(), subtitle=`${order.id} · ${order.customer}`;
  if(state==="LOADING")return bj05Loading(title,subtitle,["heading","row","card","card"]);
  const q=io05Queue(order), waiting=q==="WAITING", verifying=q==="VERIFYING", readOnly=waiting||verifying;
  const active=io05ActiveLines(order), done=io05FullyPickedLines(order).length;
  const notices=[
    state==="STALE_RECOVERED"?vBanner("warning","Danh sách lô đã thay đổi","Kiểm lại lô hiện hành trước khi lưu lượng đã lấy.","k7-banner--line"):"",
    waiting?vBanner("warning","Chờ đơn bán xử lý","Đơn chưa đủ hàng để tiếp tục. Kho không tự đổi kho hoặc giảm lượng của đơn."):"",
    verifying?vBanner("warning","Đang xác minh bàn giao","Không lấy hoặc bàn giao lại đơn này cho tới khi kết quả lần bàn giao trước được xác minh."):""
  ].join("");
  const context=`<div class="bj05-context-row k7-mobile-only"><span>${esc(order.warehouse)} · Giao một phần: ${order.partialHandoverAllowed?"Được":"Không"}</span>${bj05Link("Xem giữ hàng",'data-io05-go-reservation')}</div>`;
  const lotRows=io05LotRows(order).map(r=>({...r,...io05WebCells(r,readOnly)}));
  const columns=[{key:"product",label:"Sản phẩm",html:true},{key:"lot",label:"Lô",html:true},{key:"expiry",label:"HSD",html:true,mono:true},{key:"need",label:"Cần lấy",html:true,align:"end",mono:true},{key:"picked",label:"Đã lấy",html:true,align:"end"},{key:"action",label:"",html:true,align:"end"}];
  const table=k7Table({columns,rows:lotRows,mobileRow:(r)=>io05MobileLotRow(r,readOnly),caption:"Hàng cần lấy theo lô",rowAttr:(r)=>r.allocation?`data-io05-lot-row="${escapeAttribute(r.allocation.id)}"`:`data-io05-done-row="${escapeAttribute(r.line.id)}"`});
  const webCorrections=readOnly?"":io05AllAllocations(order).filter(({allocation})=>io05CorrectionPending(allocation)).map(({line,allocation})=>vBanner("warning","Cần điều chỉnh hàng đang cầm",esc(io05CorrectionText(line,allocation)),"k7-web-only k7-banner--line")).join("");
  const note=`<p class="bj05-business-note" data-ds-component="VText">Tồn vật lý chỉ giảm khi xác nhận bàn giao.</p>`;
  const bulk=readOnly||io05PickableAllocations(order).length<2?"":`<div class="bj05-bulk">${bj05Button("Lấy đủ tất cả",'data-io05-action="pick-all-full"')}</div>`;
  const main=`${notices}${verifying||waiting?"":bj05Progress(done,active.length)}${context}${bulk}${webCorrections}${table}${note}`;
  const body=`<div class="bj05-pick">${k7Split({main,aside:bj05Facts(order,{withLink:true}),wideMain:true,asideWebOnly:true})}</div>${bj05PickEditorSheet(io05FindAllocation(io05ActiveAllocationId)?.line,io05CurrentAllocation())}${bj05OverrideSheet(io05FindAllocation(io05ActiveAllocationId)?.line,io05CurrentAllocation())}`;
  const actions=readOnly?"":k4ReasonFooter({label:"Rà soát bàn giao",attr:'data-io05-action="review-handover"',disabled:!io05CanReview(),reason:io05ReviewReason()});
  return bj05Shell({title,subtitle,body,actions});
}

/* ---------- SCR-028 Rà soát bàn giao ---------- */

function io05HandoverRows(order,state){
  const partial=io05PartialAllowed(order,state), blocked=state==="PARTIAL_BLOCKED";
  return io05AllAllocations(order).filter(({allocation})=>io05AllocationRemainingPicked(allocation)>0&&!io05CorrectionPending(allocation)).map(({line,allocation:a})=>{
    const available=io05AllocationRemainingPicked(a), qty=Number(io05HandoverByAllocation[a.id]??available), step=Number(line.quantityStep||1);
    const editable=partial&&!blocked;
    const edit=editable?k7EditCell({value:qty,attr:`data-io05-handover-allocation="${escapeAttribute(a.id)}" max="${available}" step="${step}"`,unit:line.uom,label:`Lượng thực giao ${io05LotLabel(a)} ${line.name}`}):`${qty} ${esc(line.uom)}`;
    return {line,allocation:a,available,qty,editable,productHtml:`<strong>${esc(line.name)}</strong><small>${esc(line.code)}</small>`,lot:esc(io05LotLabel(a)),pickedText:`${available} ${esc(line.uom)}`,edit};
  });
}
function io05HandoverCard(r){
  const control=r.editable?ds24TextField("Lượng thực giao",r.qty,`data-io05-handover-allocation="${escapeAttribute(r.allocation.id)}" type="number" min="0" max="${r.available}" step="${Number(r.line.quantityStep||1)}" inputmode="decimal" aria-label="Lượng thực giao ${escapeAttribute(io05LotLabel(r.allocation))} ${escapeAttribute(r.line.name)}"`,`Tối đa ${r.available} ${r.line.uom}`):ds24KeyValueRow("Lượng thực giao",`${r.qty} ${r.line.uom}`);
  return `<div class="bj05-handover-card">${ds24ListRow({title:r.line.name,subtitle:`${r.line.code} · ${io05LotLabel(r.allocation)}`,leading:"package",type:"Status",density:"Compact",interactive:false})}${ds24KeyValueRow("Đã lấy",`${r.available} ${r.line.uom}`)}${control}</div>`;
}
function io05HandoverSummary(){
  return `<section class="bj05-summary" data-io05-handover-summary>${ds24KeyValueRow("Giao lần này",`${io05HandoverProductCount()} mặt hàng`,true,'data-io05-summary-in-this')}${ds24KeyValueRow("Còn lại sau lần này",`${io05RemainingProductCountAfterHandover()} mặt hàng`,false,'data-io05-summary-remaining')}</section>`;
}
function render028BJ05(state){
  const title="Rà soát bàn giao";
  io05Seed("SCR-028",state);
  if(state==="PERMISSION_DENIED")return bj05Denied(title);
  const order=io05CurrentOrder(), subtitle=`${order.id} · ${order.customer}`;
  if(state==="LOADING")return bj05Loading(title,subtitle,["heading","card","row","row"]);
  if(state==="SOURCE_CHANGED")return bj05Shell({title,subtitle,body:k1Stale({title:"Thông tin lấy hàng đã thay đổi",description:"Không thể dùng bản rà soát hiện tại. Hãy xem lại hàng cần lấy đã được cập nhật.",actionLabel:"Xem hàng cần lấy đã cập nhật",actionAttr:'data-io05-action="back-to-pick"'})});
  io05SyncHandover();
  const blocked=state==="PARTIAL_BLOCKED";
  const rows=io05HandoverRows(order,state);
  const banner=blocked?vBanner("error","Đơn này yêu cầu giao đủ","Chưa thể bàn giao một phần. Phần thiếu phải được đơn bán xử lý trước."):"";
  const recipient=`<section class="bj05-section">${ds24SectionTitle("Giao cho")}${dsSegmented({items:IO05_RECIPIENTS,value:io05Recipient,attr:"data-io05-recipient",label:"Giao cho"})}</section>`;
  const aside=`${recipient}<section class="bj05-section">${ds24SectionTitle("Bàn giao lần này")}${io05HandoverSummary()}</section>`;
  const columns=[{key:"productHtml",label:"Sản phẩm",html:true},{key:"lot",label:"Lô",html:true},{key:"pickedText",label:"Đã lấy",html:true,align:"end",mono:true},{key:"edit",label:"Lượng thực giao",html:true,align:"end"}];
  const table=rows.length?k7Table({columns,rows,mobileRow:io05HandoverCard,caption:"Hàng bàn giao theo lô"}):ioEmpty("Chưa có hàng đã lấy","Quay lại Hàng cần lấy để xác nhận lượng đã lấy trước khi bàn giao.");
  const main=`${banner}<section class="bj05-section">${ds24SectionTitle("Xác nhận hàng đã giao",io05PartialAllowed(order,state)&&!blocked?"Nhập lượng thực tế theo từng lô":"Đối chiếu theo lượng đã lấy")}${table}</section><p class="field-error bj05-field-error" data-io05-handover-error hidden></p><p class="bj05-business-note" data-ds-component="VText">Xác nhận khi hàng đã giao thực tế. Tồn vật lý chỉ giảm sau bước này.</p>`;
  // Thứ tự đọc: "Giao cho" và tóm tắt trước bảng (cả iPhone lẫn bàn phím); web đặt lại cột bằng CSS.
  const body=`<div class="bj05-handover"><div class="k7-split k7-split--wide-main"><aside class="k7-split__aside">${aside}</aside><div class="k7-split__main">${main}</div></div></div>`;
  const disabled=blocked||io05HandoverInvalid()||io05HandoverTotal()<=0;
  return bj05Shell({title,subtitle,body,actions:k4ReasonFooter({label:"Xác nhận đã bàn giao",attr:'data-io05-action="confirm-handover"',disabled,reason:blocked?io05RequireFullReason(order):""})});
}

/* ---------- SCR-029 Kết quả bàn giao (K3 / K4) ---------- */

function render029BJ05(state){
  const title="Kết quả bàn giao";
  io05Seed("SCR-029",state);
  if(state==="PERMISSION_DENIED")return bj05Denied(title,false);
  if(state==="LOADING")return bj05Loading(title,undefined,["heading","card","row"],false);
  io05DemoResult(state);
  const r=io05LastResult, order=io05CurrentOrder(), orderId=r?.orderId||order.id, customer=r?.customer||order.customer;
  if(["UNKNOWN","COMMIT_UNKNOWN"].includes(state)){
    io05MarkUnknown(order);order.unknownLocked=true;
    return k3Unknown({operation:"Bàn giao hàng",scope:`${order.id} · ${order.customer}`,ref:order.operationId,sentAt:"16/09/2026 13:08",sourceFlow:"UIF-05",exitAttr:k1ExitAttr("SCR-025"),handoff:{operation:order.operationId,scope:`${order.customer} · ${order.warehouse}`}});
  }
  if(state==="REJECTED_EXECUTION")return k4Result({screenTitle:title,kind:"warning",title:"Chưa thể bàn giao",description:"Dữ liệu hiện hành đã thay đổi nên chưa ghi giảm tồn. Hãy xem lại hàng cần lấy trước khi xác nhận lần nữa.",facts:[["Đơn",orderId],["Tồn vật lý","Không thay đổi"]],next:[{label:"Xem hàng cần lấy đã cập nhật",attr:'data-io05-action="back-to-pick"',primary:true}]});
  const partial=state==="PARTIAL_COMPLETED"||(r&&!r.full);
  const facts=[["Đơn",orderId],["Khách hàng",customer],["Giao cho",io05RecipientLabel(r?.recipient)],["Bàn giao lúc",r?.confirmedAt||"—"],["Người bàn giao",r?.actorName||IO05_ACTOR.name]];
  const detailCount=r?io05ResultRows(r).length+io05ActiveLines(io05Orders.find(o=>o.id===r.orderId)).length:0;
  const button=detailCount?`${bj05Link(`Xem ${detailCount} dòng hàng`,'data-io05-result-detail')}${bj05ResultSheet(r)}`:"";
  const toQueue={label:"Về danh sách đơn cần lấy",attr:'data-io05-action="result-to-queue"'};
  const next=partial?[toQueue,{label:"Tiếp tục phần còn lại",attr:'data-io05-action="continue-remaining"',primary:true}]:(io05NextActionableOrder()?[toQueue,{label:"Lấy đơn tiếp theo",attr:'data-io05-next-order',primary:true}]:[{...toQueue,primary:true}]);
  return k4Result({screenTitle:title,title:partial?"Đã bàn giao một phần":"Đã bàn giao toàn bộ",description:partial?"Đã ghi giảm tồn theo đúng lượng thực bàn giao. Phần còn lại tiếp tục ở đơn này.":"Tồn vật lý đã giảm theo đúng lượng và lô thực tế bàn giao.",facts,button,next});
}

onScreenEnter["UIF-05:SCR-028"] = () => { const o = io05CurrentOrder(); o.reviewSourceVersion = o.sourceVersion; };
// Đi giữa các màn bằng navigate (kể cả nút quay lại) là đi trong luồng: trạng thái hiện tại là "đã biết", không dựng lại đơn.
["SCR-025", "SCR-026", "SCR-028", "SCR-029"].forEach((id) => {
  const prev = onScreenEnter[`UIF-05:${id}`];
  onScreenEnter[`UIF-05:${id}`] = () => { prev?.(); io05ExpectedState[id] = stateByScreen[id]; };
});
onEntry["UIF-05:order-task"] = () => { io05ResetUi(); io05SetState("SCR-026", "READY"); };

// Cả hai ô nhập (iPhone và web) cùng có trong màn; dựng lại thì giữ cuộn, và trả focus về ô / nút vừa dùng.
function io05Rerender(focusSelector=""){
  const top=document.querySelector("#app-screen .app-content")?.scrollTop||0;
  renderAppScreen();
  const content=document.querySelector("#app-screen .app-content"); if(content)content.scrollTop=top;
  if(focusSelector)[...document.querySelectorAll(focusSelector)].find(el=>el.offsetParent!==null)?.focus({preventScroll:true});
}

Object.assign(renderers, {
  "SCR-025": render025BJ05,
  "SCR-026": render026BJ05,
  "SCR-028": render028BJ05,
  "SCR-029": render029BJ05,
});
// SCR-027 đã gộp vào SCR-026 (v5.11.0): đường cũ mở Hàng cần lấy của đơn hiện tại.
screenAliases["UIF-05"] = Object.assign(screenAliases["UIF-05"] || {}, { "SCR-027": "SCR-026" });
{ const a = screenAliases[activeFlowId]?.[activeScreenId]; if (Array.isArray(a)) { activeFlowId = a[0]; activeScreenId = a[1]; } else if (a) activeScreenId = a; }

onUnknownHandoff["UIF-05"] = () => {
  const o = io05CurrentOrder();
  if (o) o.unknownLocked = true;
};
onUnknownResolved["UIF-05"] = ({ operationId, outcome }) => {
  const o = io05Orders.find((x) => x.operationId === operationId || x.verificationOperationId === operationId) || io05Orders.find((x) => x.unknownLocked) || io05CurrentOrder();
  if (!o) return;
  o.unknownLocked = false; o.verificationOperationId = "";
  // Lần bàn giao chưa rõ là một phần của đơn: đã ghi → đơn còn phần chưa giao; chưa ghi → vẫn phải bàn giao lại.
  o.queue = "ACTIONABLE"; o.status = outcome === "RECORDED" ? "Cần tiếp tục" : "Cần bàn giao"; io05SelectedOrderId = o.id;
};

function updateIO05HandoverValidation(input){
  const id=input.dataset.io05HandoverAllocation;io05HandoverByAllocation[id]=Math.max(0,Number(input.value)||0);
  const invalid=io05HandoverInvalid();const total=io05HandoverTotal();
  const err=document.querySelector('[data-io05-handover-error]');if(err){err.hidden=!invalid;err.textContent='Lượng bàn giao không được vượt lượng đã lấy nhưng chưa bàn giao của từng lô.';}
  document.querySelectorAll('[data-io05-summary-in-this]').forEach(el=>{el.textContent=`${io05HandoverProductCount()} mặt hàng`;});
  document.querySelectorAll('[data-io05-summary-remaining]').forEach(el=>{el.textContent=`${io05RemainingProductCountAfterHandover()} mặt hàng`;});
  document.querySelectorAll(`[data-io05-handover-allocation="${CSS.escape(id)}"]`).forEach(el=>{if(el!==input)el.value=input.value;});
  const btn=document.querySelector('[data-io05-action="confirm-handover"]');if(btn)btn.disabled=invalid||total<=0;
}
// Ô "Đã lấy" ở bảng web: hợp lệ thì lưu ngay; vượt mức thì báo lỗi ngay dưới ô và chưa lưu.
function updateIO05PickedCell(input){
  const hit=io05FindAllocation(input.dataset.io05PickedAllocation); if(!hit)return;
  const {line,allocation:a}=hit, need=io05AllocationNeed(a), raw=input.value, v=Number(raw);
  if(raw==="")return;
  if(Number.isNaN(v)||v<0||v>need){
    io05PickedError[a.id]=true;
    const box=input.closest(".k7-edit"); if(!box)return; box.classList.add("k7-edit--error"); input.setAttribute("aria-invalid","true");
    let msg=box.querySelector(".field-error"); if(!msg){msg=document.createElement("small");msg.className="field-error";msg.setAttribute("role","alert");box.appendChild(msg);}
    msg.textContent=`Số lượng đã lấy không được vượt ${need} ${line.uom}.`; return;
  }
  delete io05PickedError[a.id];
  a.pickedQty=Number(a.consumedQty||0)+v; io05HandoverByAllocation[a.id]=io05AllocationRemainingPicked(a);
  io05Rerender(`[data-io05-picked-allocation="${CSS.escape(a.id)}"]`);
}

document.addEventListener("input", (event) => {
  if (activeFlowId !== "UIF-05") return;
  if (event.target.matches("[data-io05-search]")) { io05Query = event.target.value; ioFilterRows("io05", io05Query); return; }
  if (event.target.matches("[data-io05-picked-allocation]")) { updateIO05PickedCell(event.target); return; }
  if (event.target.matches("[data-io05-handover-allocation]")) { updateIO05HandoverValidation(event.target); return; }
  if (event.target.matches("[data-io05-override-reason]")) { io05OverrideReason = event.target.value; const b = document.querySelector('[data-io05-action="confirm-lot-override"]'); if (b) b.disabled = !io05OverrideReason.trim() || !io05OverrideLot; return; }
  if (event.target.matches("[data-io05-pick-draft]")) { io05PickDraft = event.target.value; const a = io05CurrentAllocation(); const b = document.querySelector('[data-io05-action="update-pick-allocation"]'); if (b) b.disabled = io05PickDraft === "" || Number(io05PickDraft) < 0 || Number(io05PickDraft) > io05AllocationNeed(a); return; }
});

onDialogClose["UIF-05"] = () => {
  if (!(io05OverrideOpen || io05PickEditorOpen || io05ResultSheetOpen)) return false;
  if (io05OverrideOpen) io05OverrideOpen = false; else { io05PickEditorOpen = false; io05PickDraft = ""; io05ResultSheetOpen = false; }
  renderAppScreen(); return true;
};

document.addEventListener("click", (event) => {
  if (activeFlowId !== "UIF-05") return;
  const t = event.target, hit = (sel) => t.closest?.(sel);
  let el;
  if ((el = hit("[data-io05-filter]"))) { event.preventDefault(); io05QueueFilter = el.dataset.io05Filter; return renderAppScreen(); }
  if ((el = hit("[data-io05-order]"))) {
    event.preventDefault(); if (el.closest("[aria-disabled='true']") || el.disabled) return;
    io05SelectedOrderId = el.dataset.io05Order; const order = io05CurrentOrder(); const q = io05Queue(order);
    if (q === "WAITING" || q === "VERIFYING") return;
    io05ResetUi(); io05ResetHandover(order);
    if (el.dataset.io05Target === "SCR-028") { io05Recipient = "COUNTER"; io05SetState("SCR-028", order.partialHandoverAllowed ? "PARTIAL_ALLOWED" : "READY"); return navigate("SCR-028"); }
    io05SetState("SCR-026", "READY"); return navigate("SCR-026");
  }
  if ((el = hit("[data-io05-pick-full]"))) { event.preventDefault(); const id = el.dataset.io05PickFull; if (io05PickFull(id)) io05Rerender(`[data-io05-pick-allocation="${CSS.escape(id)}"],[data-io05-picked-allocation="${CSS.escape(id)}"]`); return; }
  if ((el = hit("[data-io05-pick-allocation]"))) { event.preventDefault(); io05ActiveAllocationId = el.dataset.io05PickAllocation; const a = io05CurrentAllocation(); io05PickDraft = String(io05AllocationRemainingPicked(a)); io05PickEditorOpen = true; return renderAppScreen(); }
  if (t.matches?.("[data-io05-pick-editor-backdrop]")) { event.preventDefault(); io05PickEditorOpen = false; io05PickDraft = ""; return renderAppScreen(); }
  if ((el = hit("[data-io05-open-override]"))) { event.preventDefault(); io05ActiveAllocationId = el.dataset.io05OpenOverride; io05PickEditorOpen = false; io05OverrideOpen = true; io05OverrideLot = ""; io05OverrideReason = ""; return renderAppScreen(); }
  if (t.matches?.("[data-io05-override-backdrop]")) { event.preventDefault(); io05OverrideOpen = false; return renderAppScreen(); }
  if ((el = hit("[data-io05-select-lot]"))) { event.preventDefault(); io05OverrideLot = el.dataset.io05SelectLot; return renderAppScreen(); }
  if ((el = hit("[data-io05-recipient]"))) { event.preventDefault(); io05Recipient = el.dataset.io05Recipient; return io05Rerender(`[data-io05-recipient="${el.dataset.io05Recipient}"]`); }
  if (hit("[data-io05-go-reservation]")) { event.preventDefault(); bj04OrderId = io05SelectedOrderId; bj04ReturnTo = "UIF-05"; stateByScreen["SCR-021"] = "READY"; return applyEntry("UIF-04", "order-context", true); }
  if (hit("[data-io05-next-order]")) { event.preventDefault(); const next = io05NextActionableOrder(); if (!next) return; io05SelectedOrderId = next.id; io05ResetUi(); io05ResetHandover(next); io05SetState("SCR-026", "READY"); return navigate("SCR-026"); }
  if (hit("[data-io05-result-detail]")) { event.preventDefault(); io05ResultSheetOpen = true; return renderAppScreen(); }
  if (hit("[data-io05-sheet-close]") || t.matches?.("[data-io05-sheet-close-backdrop]")) { event.preventDefault(); io05ResultSheetOpen = false; return renderAppScreen(); }

  const a = hit("[data-io05-action]"); if (!a) return;
  event.preventDefault(); event.stopPropagation();
  const k = a.dataset.io05Action;
  if (k === "clear-filter") { io05QueueFilter = "ALL"; io05Query = ""; if (stateByScreen["SCR-025"] === "FILTER_EMPTY") io05SetState("SCR-025", "READY"); return renderAppScreen(); }
  if (k === "review-handover") { if (!io05CanReview()) return; io05ResetHandover(); io05Recipient = "COUNTER"; io05SetState("SCR-028", io05CurrentOrder().partialHandoverAllowed ? "PARTIAL_ALLOWED" : "READY"); return navigate("SCR-028"); }
  if (k === "pick-all-full") { if (io05PickAllFull()) io05Rerender('[data-io05-action="review-handover"]'); return; }
  if (k === "update-pick-allocation") { const al = io05CurrentAllocation(); if (!al || io05PickDraft === "" || Number(io05PickDraft) < 0 || Number(io05PickDraft) > io05AllocationNeed(al)) return; const id = al.id; al.pickedQty = Number(al.consumedQty || 0) + Number(io05PickDraft); io05HandoverByAllocation[al.id] = io05AllocationRemainingPicked(al); io05PickEditorOpen = false; io05PickDraft = ""; return io05Rerender(`[data-io05-pick-allocation="${CSS.escape(id)}"]`); }
  if (k === "close-lot-override") { io05OverrideOpen = false; return renderAppScreen(); }
  if (k === "confirm-lot-override") { if (!io05OverrideReason.trim() || !io05OverrideLot) return; const allocation = io05CurrentAllocation(); if (allocation && Number(allocation.consumedQty || 0) <= 0) { const oldLot = allocation.lot, oldPicked = io05AllocationRemainingPicked(allocation); allocation.lot = io05OverrideLot; allocation.overrideReason = io05OverrideReason; if (oldPicked > 0) { allocation.pickedQty = Number(allocation.consumedQty || 0); allocation.physicalCorrection = { kind: "MANUAL", status: "PENDING", oldLot, returnQty: oldPicked, newLot: io05OverrideLot, repickQty: oldPicked, actor: null, confirmedAt: null }; } io05HandoverByAllocation[allocation.id] = 0; const order = io05CurrentOrder(); order.allocationVersion = Number(order.allocationVersion || 0) + 1; } io05OverrideOpen = false; renderAppScreen(); return showToast("Đã cập nhật lô lấy hàng", "success"); }
  if (k === "confirm-physical-correction") { const hit2 = io05FindAllocation(a.dataset.io05Allocation); const al = hit2?.allocation; if (!al || !io05CorrectionPending(al) || io05AllocationRemainingPicked(al) < Number(al.physicalCorrection.repickQty || 0)) return; al.physicalCorrection = { ...al.physicalCorrection, status: "CONFIRMED", actor: IO05_ACTOR.name, actorId: IO05_ACTOR.id, confirmedAt: "16/09/2026 13:06" }; return io05Rerender(`[data-io05-pick-allocation="${CSS.escape(al.id)}"],[data-io05-picked-allocation="${CSS.escape(al.id)}"]`); }
  if (k === "back-to-pick") { io05SetState("SCR-026", "READY"); return navigate("SCR-026"); }
  if (k === "result-to-queue") { io05QueueFilter = "ALL"; io05Query = ""; io05SetState("SCR-025", "READY"); return navigate("SCR-025"); }
  if (k === "continue-remaining") { io05SetState("SCR-026", "READY"); return navigate("SCR-026"); }
  if (k === "confirm-handover") { if (io05HandoverInvalid() || io05HandoverTotal() <= 0) return; const result = io05ApplyHandover(); if (!result) return; io05SetState("SCR-029", result.full ? "COMPLETED" : "PARTIAL_COMPLETED"); return navigate("SCR-029"); }
});

Object.assign(window.__VET45_QA__, {
  bumpIO05Source(){const o=io05CurrentOrder();o.sourceVersion=Number(o.sourceVersion||0)+1;return o.sourceVersion;}
});
