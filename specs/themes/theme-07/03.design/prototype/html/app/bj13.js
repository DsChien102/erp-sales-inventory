/* BJ-13 — Điều chỉnh giá trị hàng nhập (UIF-13). Màn: SCR-085, SCR-086, SCR-089.
 *
 * Đã viết lại sạch (T7-P gói A5, 2026-10-17). Sửa BJ-13: sửa thẳng file này.
 */
// UIF-13 / BJ-13 v1.4.5 — Late landed cost deep Product correction.
// Allocation-method labels below are runtime fixtures returned by the preview
// model. They are not a canonical business enum; BC-IV-06/API-Q-12 owns the
// authoritative allowed set and calculation in production.
// ============================================================================
const val13Tasks = [
  {id:"LC13-001",sourceRef:"Hóa đơn vận chuyển VC-8842 · dòng 1",sourceVersion:2,evidence:"VC-8842.pdf",supplier:"Vận tải An Phát",component:"Chi phí vận chuyển",sourceAmount:1200000,currency:"VND",normalizedAmount:1200000,fxLabel:"VND",ageDays:4,status:"ACTIONABLE",waitingOwner:"",originalPeriod:"08/2026",postingPeriod:"09/2026",periodReason:"Kỳ gốc đã khóa; ghi điều chỉnh ở kỳ mở hiện tại",policyVersion:"ALC-POL-v5",allowedMethods:[{id:"FIXTURE_VALUE",label:"Theo giá trị nhập ban đầu"}],selectedMethod:"FIXTURE_VALUE",targets:[
    {id:"LC13-T1",receipt:"PN-260816-04",lineId:"ROL-401",product:"Nobivac DHPPi",code:"SP-00142",uom:"hộp",lot:"DH2507",qty:50,receivedValue:4085000,selected:true},
    {id:"LC13-T2",receipt:"PN-260816-04",lineId:"ROL-404",product:"Amoxicillin LA",code:"SP-00088",uom:"chai",lot:null,qty:24,receivedValue:2880000,selected:true},
    {id:"LC13-T3",receipt:"PN-260821-03",lineId:"ROL-512",product:"Vaccine Canine X",code:"SP-00421",uom:"lọ",lot:"CX2608",qty:40,receivedValue:4010000,selected:true}
  ]},
  {id:"LC13-002",sourceRef:"Phí bảo hiểm INS-2609-17 · dòng 2",sourceVersion:1,evidence:"INS-2609-17.pdf",supplier:"Bảo hiểm Minh Thành",component:"Phí bảo hiểm hàng mua",sourceAmount:250,currency:"USD",normalizedAmount:6125000,fxRate:24500,fxLabel:"Tỷ giá kế toán 24.500 VND/USD",ageDays:2,status:"ACTIONABLE",waitingOwner:"",originalPeriod:"09/2026",postingPeriod:"09/2026",periodReason:"Kỳ gốc đang mở",policyVersion:"ALC-POL-v5",allowedMethods:[{id:"FIXTURE_VALUE",label:"Theo giá trị nhập ban đầu"}],selectedMethod:"FIXTURE_VALUE",targets:[
    {id:"LC13-T4",receipt:"PN-260901-03",lineId:"ROL-601",product:"Vaccine Canine X",code:"SP-00421",uom:"lọ",lot:"CX2609",qty:10,receivedValue:1002450,selected:true},
    {id:"LC13-T5",receipt:"PN-260901-08",lineId:"ROL-633",product:"Doxycycline 100mg",code:"SP-00611",uom:"hộp",lot:null,qty:60,receivedValue:7200000,selected:true}
  ]},
  {id:"LC13-003",sourceRef:"Hóa đơn vận chuyển VC-8890 · dòng 1",sourceVersion:1,evidence:"VC-8890.pdf",supplier:"Logistics Đông Dương",component:"Chi phí vận chuyển",sourceAmount:180,currency:"USD",normalizedAmount:null,fxLabel:"",ageDays:6,status:"WAITING",waitingOwner:"Chờ nguồn hoàn tất quy đổi giá trị",originalPeriod:"08/2026",postingPeriod:"",periodReason:"",policyVersion:"",allowedMethods:[],selectedMethod:"",targets:[]},
  {id:"LC13-004",sourceRef:"Điều chỉnh chiết khấu CK-2609-06 · dòng 1",sourceVersion:3,evidence:"CK-2609-06.pdf",supplier:"Minh Dũng",component:"Điều chỉnh chiết khấu mua",sourceAmount:-350000,currency:"VND",normalizedAmount:-350000,fxLabel:"VND",ageDays:1,status:"ACTIONABLE",waitingOwner:"",originalPeriod:"09/2026",postingPeriod:"09/2026",periodReason:"Kỳ gốc đang mở",policyVersion:"ALC-POL-v5",allowedMethods:[{id:"FIXTURE_VALUE",label:"Theo giá trị nhập ban đầu"}],selectedMethod:"FIXTURE_VALUE",targets:[
    {id:"LC13-T6",receipt:"PN-260902-07",lineId:"ROL-407",product:"Dung dịch sát khuẩn",code:"SP-00510",uom:"chai",lot:null,qty:12,receivedValue:552000,selected:true},
    {id:"LC13-T7",receipt:"PN-260902-07",lineId:"ROL-408",product:"Bơm tiêm 5ml",code:"SP-00511",uom:"hộp",lot:null,qty:8,receivedValue:640000,selected:true}
  ]}
];
let val13SelectedTaskId="LC13-001", val13Query="", val13Filter="ALL", val13ReviewSourceVersion=null, val13PreviewHash=null, val13LastSourceChange=null, val13LastResult=null, val13OperationSeq=1;
function val13Current(){return val13Tasks.find(t=>t.id===val13SelectedTaskId)||val13Tasks[0];}
function val13FmtMoney(value){const n=Number(value||0);return `${new Intl.NumberFormat('vi-VN').format(n)} đ`;}
function val13FmtSourceAmount(t){const amount=new Intl.NumberFormat('vi-VN',{maximumFractionDigits:2}).format(Number(t.sourceAmount||0));return `${amount} ${t.currency}`;}
function val13SelectedTargets(t=val13Current()){return (t.targets||[]).filter(x=>x.selected);}
function val13TaskSearchText(t){return ioNormalizeSearch(`${t.id} ${t.sourceRef} ${t.supplier} ${t.component}`);}
function val13QueueTitle(t){return String(t.sourceRef||"").replace(/^(Hóa đơn vận chuyển|Phí bảo hiểm|Điều chỉnh chiết khấu)\s+/i,"");}
function val13AllocationWeight(target,method){return method==="FIXTURE_QTY"?Math.max(0,Number(target.qty)||0):Math.max(0,Number(target.receivedValue)||0);}
function val13Preview(t=val13Current()){
  const targets=val13SelectedTargets(t);const total=Number(t.normalizedAmount||0);if(!targets.length||t.normalizedAmount==null)return [];
  const weights=targets.map(x=>val13AllocationWeight(x,t.selectedMethod));const weightTotal=weights.reduce((a,b)=>a+b,0)||targets.length;
  let used=0;return targets.map((target,index)=>{let amount;if(index===targets.length-1)amount=total-used;else{const weight=weightTotal?weights[index]:1;amount=Math.round(total*(weight/weightTotal));used+=amount;}return {...target,allocatedAmount:amount,roundingAdjustment:index===targets.length-1?total-used-amount:0};});
}
function val13PreviewHashOf(t=val13Current()){return `${t.id}|v${t.sourceVersion}|${t.selectedMethod}|${val13SelectedTargets(t).map(x=>x.id).sort().join(',')}|${t.normalizedAmount}`;}
function val13CanOpenAllocation(t=val13Current()){return t.status==="ACTIONABLE"&&t.normalizedAmount!=null&&val13SelectedTargets(t).length>0;}
function val13CanPreview(t=val13Current()){return val13CanOpenAllocation(t)&&t.allowedMethods.some(m=>m.id===t.selectedMethod);}
function val13StatusMeta(t){if(t.status==="WAITING")return [t.waitingOwner||"Đang chờ","neutral"];return ["Có thể xử lý","success"];}
function val13ResetTaskDraft(t){for(const target of (t.targets||[]))target.selected=true;t.selectedMethod=t.allowedMethods?.length===1?t.allowedMethods[0].id:"";val13ReviewSourceVersion=null;val13PreviewHash=null;val13LastSourceChange=null;}
function val13SourceCard(t){
  const [rawLabel,rawTone]=val13StatusMeta(t);const label=t.status==="WAITING"?"Đang chờ":rawLabel;
  const context=ds24ContextStatusRow({title:t.sourceRef,subtitle:`${t.component} · ${t.supplier}`,label,tone:valuationDsTone(rawTone),leading:null});
  const facts=`${ds24InfoRow("Giá trị nguồn",val13FmtSourceAmount(t))}${t.currency!=="VND"&&t.fxLabel?ds24InfoRow("Tỷ giá",t.fxLabel):""}${t.normalizedAmount!=null?ds24KeyValueRow("Sau chuẩn hóa",val13FmtMoney(t.normalizedAmount),true):""}${ds24InfoRow("Lần cập nhật nguồn",`Lần ${t.sourceVersion}`)}${ds24InfoRow("Bằng chứng",t.evidence)}`;
  return `${context}${ds24InfoGroup("Chi tiết nguồn",facts,"valuation-info-group valuation-info-group--wrap val13-source-card")}`;
}
function val13TargetHtml(t){
  return (t.targets||[]).map(target=>`<button type="button" class="val13-target-row ${target.selected?'is-selected':''}" data-val13-target="${target.id}" aria-pressed="${target.selected}" data-composed-from="VCheckbox,VText"><span class="valuation-selection-control val13-check-mark" aria-hidden="true">${target.selected?icon('check','icon--xs'):''}</span><span class="val13-target-copy"><strong>${esc(target.product)}</strong><small>${esc(target.receipt)} · ${esc(target.code)} · ${target.qty} ${esc(target.uom)}${target.lot?` · Lô ${esc(target.lot)}`:""}</small></span></button>`).join('');
}
function val13AllocationRows(t=val13Current()){
  const rows=val13Preview(t);return rows.map(row=>`<div class="val13-allocation-row valuation-allocation-row" data-composed-from="VText"><span><strong>${esc(row.product)}</strong><small>${esc(row.receipt)} · ${row.qty} ${esc(row.uom)}${row.lot?` · Lô ${esc(row.lot)}`:""}</small></span><strong class="valuation-amount">${esc(val13FmtMoney(row.allocatedAmount))}</strong></div>`).join('');
}
function val13DirtyScope(t=val13Current()){return [...new Map(val13Preview(t).map(x=>[`${x.product}|${x.uom}`,`${x.product} · ${x.uom}`])).values()];}
function val13PeriodCard(t){
  const differs=t.originalPeriod&&t.postingPeriod&&t.originalPeriod!==t.postingPeriod;
  return `${differs?vBanner("info","Ghi nhận ở kỳ mở hiện tại",t.periodReason||"Kỳ gốc đã khóa; điều chỉnh vẫn liên kết về kỳ gốc."):""}${ds24InfoGroup("Kỳ ghi nhận",`${ds24InfoRow("Kỳ gốc",t.originalPeriod||"—")}${ds24InfoRow("Kỳ ghi nhận",t.postingPeriod||"—")}`,"valuation-info-group")}`;
}
function val13ReviewBody(t){
  const allocations=val13Preview(t),method=t.allowedMethods.find(m=>m.id===t.selectedMethod)?.label||"—",total=allocations.reduce((sum,x)=>sum+x.allocatedAmount,0);
  const allocation=`${ds24SectionTitle("Phân bổ sẽ ghi",`${allocations.length} dòng đích`)}${ds24GroupedCollection(`${val13AllocationRows(t)}<div class="valuation-total-strip valuation-total-strip--inside">${ds24KeyValueRow("Tổng phân bổ",val13FmtMoney(total),true)}</div>`,"valuation-allocation-collection val13-review-group","VText,DS v2 / Key-value Row")}`;
  const methodInfo=ds24InfoGroup("Căn cứ phân bổ",`${ds24KeyValueRow("Giá trị sau chuẩn hóa",val13FmtMoney(t.normalizedAmount),true)}${ds24InfoRow("Phương pháp",method)}`,"valuation-info-group");
  const effects=ds24InfoGroup("Tác động sau ghi",`${ds24InfoRow("Số lượng tồn kho","Không thay đổi")}${ds24InfoRow("Giá vốn chính thức","Chưa tự công bố lại")}${ds24InfoRow("Cần tính lại",val13DirtyScope(t).join("; ")||"—")}`,"valuation-info-group valuation-info-group--wrap");
  return `${val13SourceCard(t)}${methodInfo}${allocation}${val13PeriodCard(t)}${effects}`;
}
function val13Commit(){const t=val13Current();const allocations=val13Preview(t);val13LastResult={operationId:`LC13-OP-${String(val13OperationSeq++).padStart(3,'0')}`,taskId:t.id,sourceRef:t.sourceRef,component:t.component,normalizedAmount:t.normalizedAmount,postingPeriod:t.postingPeriod,originalPeriod:t.originalPeriod,allocations:allocations.map(x=>({...x})),dirtyScope:val13DirtyScope(t)};t.status="COMPLETED";return val13LastResult;}
function val13Result(){return val13LastResult||{operationId:"LC13-OP-PREVIEW",taskId:val13Current().id,sourceRef:val13Current().sourceRef,component:val13Current().component,normalizedAmount:val13Current().normalizedAmount,postingPeriod:val13Current().postingPeriod,originalPeriod:val13Current().originalPeriod,allocations:val13Preview(),dirtyScope:val13DirtyScope()};}
function val13ApplySourceUpdate(){const t=val13Current();if(t.status!=="ACTIONABLE")return;t.sourceVersion+=1;const before=t.normalizedAmount;t.normalizedAmount=Number(t.normalizedAmount||0)+100000;val13LastSourceChange={from:val13FmtMoney(before),to:val13FmtMoney(t.normalizedAmount),version:t.sourceVersion};if(activeScreenId==="SCR-088")stateByScreen["SCR-088"]="SOURCE_CHANGED";render();}
window.val13ApplySourceUpdate=val13ApplySourceUpdate;

// ============================================================================

/* chuẩn hoá + helper thắng (v398) */
(()=>{
if(typeof val13Tasks==='undefined') return;

const fmtMoney=(n)=>`${Number(n||0)<0?'− ':''}${Math.abs(Math.round(Number(n)||0)).toLocaleString('vi-VN')} đ`;
const stable=(v)=>{
  const s=typeof v==='string'?v:JSON.stringify(v,Object.keys(v||{}).sort());
  let h=2166136261>>>0; for(let i=0;i<s.length;i++){h^=s.charCodeAt(i);h=Math.imul(h,16777619)>>>0;}
  return `fixture-hash-${h.toString(16).padStart(8,'0')}`;
};
const stableObj=(obj)=>{
  if(Array.isArray(obj)) return obj.map(stableObj);
  if(obj&&typeof obj==='object') return Object.fromEntries(Object.keys(obj).sort().map(k=>[k,stableObj(obj[k])]));
  return obj;
};
const stableHash=(obj)=>stable(JSON.stringify(stableObj(obj)));

function periodForReceipt(receipt){
  if(/2608/.test(receipt)) return {businessDate:'21/08/2026',originalPeriod:'08/2026',postingPeriod:'09/2026',periodReason:'Kỳ gốc đã khóa; ghi điều chỉnh ở kỳ mở hiện tại'};
  if(/2609/.test(receipt)) return {businessDate:'02/09/2026',originalPeriod:'09/2026',postingPeriod:'09/2026',periodReason:'Kỳ gốc đang mở'};
  return {businessDate:'16/09/2026',originalPeriod:'09/2026',postingPeriod:'09/2026',periodReason:'Kỳ gốc đang mở'};
}

// Convert legacy fixtures into the v3.9.8 economic-source / valuation-exposure model.
for(const t of val13Tasks){
  t.sourceComponentKey=t.sourceComponentKey||`LCOMP-${t.id.replace('LC13-','')}`;
  t.operationId=t.operationId||`LC13-CMD-${t.sourceComponentKey}`;
  t.sourceRevision=Number(t.sourceVersion||1);
  t.accountingRoute=t.accountingRoute||'LATE';
  t.taxTreatmentVersion=t.taxTreatmentVersion||'TAX-v3';
  t.fxSourceVersion=t.currency==='VND'?'VND':(t.fxSourceVersion||'FX-ACCOUNTING-v7');
  t.targetScopeMode=t.targetScopeMode||'FIXED';
  t.targetScopeKey=t.targetScopeKey||`TS-${t.sourceComponentKey}`;
  t.targetScopeVersion=t.targetScopeVersion||'v1';
  for(const x of (t.targets||[])){
    const p=periodForReceipt(x.receipt||'');
    x.initialValued=x.initialValued!==false;
    x.receiptItemRef=x.receiptItemRef||`${x.receipt}-ITEM-${x.lineId}`;
    x.valuationExposureKey=x.valuationExposureKey||`VE-${x.lineId}`;
    x.exposureVersion=Number(x.exposureVersion||1);
    x.baseQty=Number(x.baseQty||x.qty||0);
    x.initialDirectValue=Number(x.initialDirectValue??x.receivedValue??0);
    x.businessDate=x.businessDate||p.businessDate;
    x.originalPeriod=x.originalPeriod||p.originalPeriod;
    x.postingPeriod=x.postingPeriod||p.postingPeriod;
    x.periodReason=x.periodReason||p.periodReason;
    x.receiptValuationRefs=x.receiptValuationRefs||[`RV-${x.lineId}-1`];
    x.exposureHash=stableHash({key:x.valuationExposureKey,version:x.exposureVersion,qty:x.baseQty,value:x.initialDirectValue,refs:x.receiptValuationRefs,businessDate:x.businessDate,original:x.originalPeriod,posting:x.postingPeriod});
    x.selected=t.targetScopeMode==='FIXED'?true:(x.selected!==false);
  }
  t.targetScopeHash=stableHash({key:t.targetScopeKey,version:t.targetScopeVersion,members:(t.targets||[]).map(x=>x.valuationExposureKey).sort()});
}

// Add a representative late-route component that must wait for initial valuation.
if(!val13Tasks.some(t=>t.id==='LC13-005')){
  val13Tasks.push({id:'LC13-005',sourceRef:'Phí kiểm định QC-2609-22 · dòng 1',sourceVersion:1,sourceRevision:1,sourceComponentKey:'LCOMP-QC-2609-22-1',accountingRoute:'LATE',supplier:'Trung tâm kiểm định',component:'Phí kiểm định hàng mua',sourceAmount:420000,currency:'VND',normalizedAmount:420000,fxLabel:'VND',status:'WAITING',waitingOwner:'Chờ xác nhận giá ban đầu của 1 dòng',taxTreatmentVersion:'TAX-v3',fxSourceVersion:'VND',targetScopeMode:'FIXED',targetScopeKey:'TS-LCOMP-QC-2609-22-1',targetScopeVersion:'v1',policyVersion:'ALC-POL-v5',allowedMethods:[],selectedMethod:'',targets:[{id:'LC13-T8',receipt:'PN-260915-02',lineId:'ROL-702',product:'Oxytetracycline 20%',code:'SP-00702',uom:'chai',lot:null,qty:20,baseQty:20,initialDirectValue:0,initialValued:false,receiptItemRef:'PN-260915-02-ITEM-ROL-702',valuationExposureKey:'VE-ROL-702',exposureVersion:1,businessDate:'15/09/2026',originalPeriod:'09/2026',postingPeriod:'09/2026',periodReason:'Kỳ gốc đang mở',receiptValuationRefs:[],selected:true}]});
  const t=val13Tasks[val13Tasks.length-1],x=t.targets[0];x.exposureHash=stableHash({key:x.valuationExposureKey,version:1,qty:x.baseQty,value:0,refs:[],businessDate:x.businessDate,original:x.originalPeriod,posting:x.postingPeriod});t.targetScopeHash=stableHash({key:t.targetScopeKey,version:t.targetScopeVersion,members:[x.valuationExposureKey]});
}

function selectedTargets(t=val13Current()){
  return (t.targets||[]).filter(x=>t.targetScopeMode==='FIXED'?true:x.selected);
}
function metricSnapshot(t,x,method=t.selectedMethod){
  const quantityMethod=method==='FIXTURE_QTY';
  const value=quantityMethod?Math.max(0,Number(x.quantityMetricValue)||0):Math.max(0,Number(x.initialDirectValue)||0);
  const unit=quantityMethod?(x.quantityMetricUnit||''):'initial_valuation_value_vnd';
  const version=quantityMethod?(x.quantityMetricVersion||'METRIC-QTY-v2'):'METRIC-INITIAL-VALUE-v2';
  return {method,metricValue:value,unit,metricVersion:version,metricHash:stableHash({exposure:x.valuationExposureKey,method,value,unit,version})};
}
function methodEligible(t,method=t.selectedMethod){
  const targets=selectedTargets(t);if(!targets.length)return false;
  const metrics=targets.map(x=>metricSnapshot(t,x,method));
  if(method==='FIXTURE_QTY'){const units=new Set(metrics.map(m=>m.unit).filter(Boolean));if(units.size!==1||metrics.some(m=>!m.unit))return false;}
  return metrics.reduce((n,m)=>n+m.metricValue,0)>0;
}
function lateCostBasisPayload(t=val13Current()){
  const targets=selectedTargets(t).slice().sort((a,b)=>a.valuationExposureKey.localeCompare(b.valuationExposureKey));
  return {sourceComponentKey:t.sourceComponentKey,sourceRevision:Number(t.sourceVersion||t.sourceRevision||1),sourceRef:t.sourceRef,sourceAmount:t.sourceAmount,currency:t.currency,normalizedAmount:t.normalizedAmount,taxTreatmentVersion:t.taxTreatmentVersion,fxSourceVersion:t.fxSourceVersion,fxRate:t.fxRate||1,accountingRoute:t.accountingRoute,policyVersion:t.policyVersion,method:t.selectedMethod,targetScopeKey:t.targetScopeKey,targetScopeVersion:t.targetScopeVersion,targetScopeHash:t.targetScopeHash,exposures:targets.map(x=>({key:x.valuationExposureKey,version:x.exposureVersion,hash:x.exposureHash,metric:metricSnapshot(t,x),businessDate:x.businessDate,originalPeriod:x.originalPeriod,postingPeriod:x.postingPeriod}))};
}
function lateCostBasisHash(t=val13Current()){return stableHash(lateCostBasisPayload(t));}
function allocate(t=val13Current()){
  const selected=selectedTargets(t).slice().sort((a,b)=>a.valuationExposureKey.localeCompare(b.valuationExposureKey));
  const total=Number(t.normalizedAmount||0); if(!selected.length||t.normalizedAmount==null||!t.selectedMethod)return [];
  const metrics=selected.map(x=>metricSnapshot(t,x));
  const weightTotal=metrics.reduce((n,m)=>n+m.metricValue,0); if(weightTotal<=0||!methodEligible(t,t.selectedMethod))return [];
  const amounts=new Map(); let used=0;
  selected.forEach((x,i)=>{
    const weight=metrics[i].metricValue;
    const amount=i===selected.length-1?total-used:Math.round(total*(weight/weightTotal));
    used+=amount; amounts.set(x.valuationExposureKey,{amount,metric:metrics[i],ratio:weight/weightTotal});
  });
  return selected.map((x,i)=>({...x,allocatedAmount:amounts.get(x.valuationExposureKey).amount,allocationMetric:amounts.get(x.valuationExposureKey).metric,roundingAdjustment:i===selected.length-1?total-selected.slice(0,-1).reduce((n,y)=>n+amounts.get(y.valuationExposureKey).amount,0)-amounts.get(x.valuationExposureKey).amount:0}));
}
function allocationHash(t=val13Current()){
  return stableHash(allocate(t).map(x=>({key:x.valuationExposureKey,amount:x.allocatedAmount,metricHash:x.allocationMetric.metricHash,original:x.originalPeriod,posting:x.postingPeriod})));
}
function combinedPreviewHash(t=val13Current()){return `${lateCostBasisHash(t)}|${allocationHash(t)}`;}
function dirtyScopes(t=val13Current()){
  const m=new Map(); for(const x of allocate(t)){const k=`${x.code}|${x.postingPeriod}`;m.set(k,{product:x.product,code:x.code,postingPeriod:x.postingPeriod,label:`${x.product} · ${x.postingPeriod}`});} return [...m.values()];
}
function periodGroups(t=val13Current()){
  const map=new Map(); for(const x of allocate(t)){const k=x.postingPeriod;const g=map.get(k)||{postingPeriod:k,originalPeriods:new Set(),reason:new Set(),count:0};g.originalPeriods.add(x.originalPeriod);if(x.periodReason)g.reason.add(x.periodReason);g.count++;map.set(k,g);}return [...map.values()].map(g=>({...g,originalPeriods:[...g.originalPeriods],reason:[...g.reason]}));
}
function allInitialValued(t=val13Current()){return selectedTargets(t).every(x=>x.initialValued);}
function canOpen(t=val13Current()){return t.status==='ACTIONABLE'&&t.accountingRoute==='LATE'&&t.normalizedAmount!=null&&selectedTargets(t).length>0&&allInitialValued(t);}
function canPreview(t=val13Current()){return canOpen(t)&&t.allowedMethods.some(m=>m.id===t.selectedMethod)&&methodEligible(t,t.selectedMethod)&&allocate(t).length>0;}

val13SelectedTargets=selectedTargets;
val13AllocationWeight=(target,method)=>metricSnapshot(val13Current(),target,method).metricValue;
val13Preview=allocate;
val13PreviewHashOf=combinedPreviewHash;
val13CanOpenAllocation=canOpen;
val13CanPreview=canPreview;
val13DirtyScope=(t=val13Current())=>dirtyScopes(t).map(x=>x.label);
val13StatusMeta=function(t){if(t.status==='WAITING')return [t.waitingOwner||'Đang chờ','neutral'];return ['', 'neutral'];};
val13ResetTaskDraft=function(t){for(const x of (t.targets||[]))x.selected=true;const eligible=(t.allowedMethods||[]).filter(m=>methodEligible(t,m.id));t.selectedMethod=eligible.length===1?eligible[0].id:(eligible.some(m=>m.id===t.selectedMethod)?t.selectedMethod:'');val13ReviewSourceVersion=null;val13PreviewHash=null;val13LastSourceChange=null;};
val13SourceCard=function(t){
  const context=ds24ContextStatusRow({title:t.sourceRef,subtitle:`${t.component} · ${t.supplier}`,label:t.status==='WAITING'?'Đang chờ':'',tone:'neutral',leading:null});
  const facts=`${ds24InfoRow('Giá trị nguồn',val13FmtSourceAmount(t))}${t.currency!=='VND'&&t.fxLabel?ds24InfoRow('Tỷ giá',t.fxLabel):''}${t.normalizedAmount!=null?ds24KeyValueRow('Sau chuẩn hóa',val13FmtMoney(t.normalizedAmount),true):''}`;
  return `${context}${ds24InfoGroup('Chi tiết nguồn',facts,'valuation-info-group valuation-info-group--wrap val13-source-card')}`;
};
val13TargetHtml=function(t){
  const fixed=t.targetScopeMode==='FIXED';
  return (t.targets||[]).map(x=>{
    const subtitle=`${x.receipt} · ${x.code} · ${x.qty} ${x.uom}${x.lot?` · Lô ${x.lot}`:''}`;
    if(fixed)return `<div class="val13-target-row is-selected v398-fixed-scope" data-valuation-exposure="${esc(x.valuationExposureKey)}" data-composed-from="VText"><span class="valuation-selection-control val13-check-mark" aria-hidden="true">${icon('check','icon--xs')}</span><span class="val13-target-copy"><strong>${esc(x.product)}</strong><small>${esc(subtitle)}</small></span></div>`;
    return `<button type="button" class="val13-target-row ${x.selected?'is-selected':''}" data-val13-target="${x.id}" data-valuation-exposure="${esc(x.valuationExposureKey)}" aria-pressed="${x.selected}" data-composed-from="VCheckbox,VText"><span class="valuation-selection-control val13-check-mark" aria-hidden="true">${x.selected?icon('check','icon--xs'):''}</span><span class="val13-target-copy"><strong>${esc(x.product)}</strong><small>${esc(subtitle)}</small></span></button>`;
  }).join('');
};
val13AllocationRows=function(t=val13Current()){
  return allocate(t).map(x=>`<div class="val13-allocation-row valuation-allocation-row" data-valuation-exposure="${esc(x.valuationExposureKey)}" data-composed-from="VText"><span><strong>${esc(x.product)}</strong><small>${esc(x.receipt)} · ${x.qty} ${esc(x.uom)}${x.lot?` · Lô ${esc(x.lot)}`:''}</small></span><strong class="valuation-amount">${esc(val13FmtMoney(x.allocatedAmount))}</strong></div>`).join('');
};
val13PeriodCard=function(t){
  const groups=periodGroups(t); if(!groups.length)return '';
  const rows=groups.map(g=>ds24InfoRow(`Ghi nhận ${g.postingPeriod}`,g.originalPeriods.length===1&&g.originalPeriods[0]===g.postingPeriod?`${g.count} dòng · cùng kỳ`:`${g.count} dòng · từ kỳ ${g.originalPeriods.join(', ')}`)).join('');
  const moved=groups.some(g=>g.originalPeriods.some(p=>p!==g.postingPeriod));
  return `${moved?vBanner('info','Có chi phí ghi ở kỳ mở','Kỳ gốc đã khóa vẫn được giữ để truy vết; adjustment được ghi ở kỳ mở theo policy.') : ''}${ds24InfoGroup('Kỳ ghi nhận',rows,'valuation-info-group')}`;
};
val13ReviewBody=function(t){
  const rows=allocate(t),method=t.allowedMethods.find(m=>m.id===t.selectedMethod)?.label||'—',total=rows.reduce((n,x)=>n+x.allocatedAmount,0);
  const allocation=`${ds24SectionTitle('Phân bổ sẽ ghi',`${rows.length} dòng`)}${ds24GroupedCollection(`${val13AllocationRows(t)}<div class="valuation-total-strip valuation-total-strip--inside">${ds24KeyValueRow('Tổng phân bổ',val13FmtMoney(total),true)}</div>`,'valuation-allocation-collection val13-review-group','VText,DS v2 / Key-value Row')}`;
  const basis=ds24InfoGroup('Căn cứ phân bổ',`${ds24KeyValueRow('Chi phí sẽ ghi',val13FmtMoney(t.normalizedAmount),true)}${ds24InfoRow('Phương pháp',method)}`,'valuation-info-group');
  const effects=ds24InfoGroup('Sau khi ghi',`${ds24InfoRow('Cần tính lại',dirtyScopes(t).map(x=>x.label).join('; ')||'—')}`,'valuation-info-group valuation-info-group--wrap');
  return `${val13SourceCard(t)}${basis}${allocation}${val13PeriodCard(t)}${effects}`;
};
val13Commit=function(){
  const t=val13Current(),rows=allocate(t),groups=periodGroups(t),basisHash=lateCostBasisHash(t),allocHash=allocationHash(t);
  const adjustmentBatches=groups.map((g,i)=>({id:`LC13-ADJ-${String(val13OperationSeq).padStart(3,'0')}-${i+1}`,postingPeriod:g.postingPeriod,originalPeriods:g.originalPeriods,allocationCount:g.count}));
  val13LastResult={operationId:t.operationId,taskId:t.id,sourceComponentKey:t.sourceComponentKey,sourceRevision:Number(t.sourceVersion||1),sourceRef:t.sourceRef,component:t.component,normalizedAmount:t.normalizedAmount,allocations:rows.map(x=>({...x})),dirtyScope:dirtyScopes(t),periodGroups:groups,adjustmentBatches,lateCostBasisHash:basisHash,allocationHash:allocHash};
  t.status='COMPLETED';return val13LastResult;
};
val13Result=function(){const t=val13Current();return val13LastResult||{operationId:t.operationId,taskId:t.id,sourceComponentKey:t.sourceComponentKey,sourceRevision:Number(t.sourceVersion||1),sourceRef:t.sourceRef,component:t.component,normalizedAmount:t.normalizedAmount,allocations:allocate(t),dirtyScope:dirtyScopes(t),periodGroups:periodGroups(t),adjustmentBatches:[],lateCostBasisHash:lateCostBasisHash(t),allocationHash:allocationHash(t)};};
val13ApplySourceUpdate=function(){const t=val13Current();if(t.status!=='ACTIONABLE')return;t.sourceVersion=Number(t.sourceVersion||1)+1;t.sourceRevision=t.sourceVersion;const before=t.normalizedAmount;t.normalizedAmount=Number(t.normalizedAmount||0)+100000;val13LastSourceChange={from:val13FmtMoney(before),to:val13FmtMoney(t.normalizedAmount),version:t.sourceVersion};if(activeScreenId==='SCR-088')stateByScreen['SCR-088']='SOURCE_CHANGED';render();};
window.val13ApplySourceUpdate=val13ApplySourceUpdate;

const val13Engine={lateCostBasisPayload,lateCostBasisHash,allocationHash,combinedPreviewHash,metricSnapshot,methodEligible,allocate,dirtyScopes,periodGroups,allInitialValued,economicIdentity:(t=val13Current())=>t.sourceComponentKey,touchExposure:(id)=>{const t=val13Current(),x=t.targets.find(y=>y.id===id);if(!x)return false;x.exposureVersion+=1;x.exposureHash=stableHash({key:x.valuationExposureKey,version:x.exposureVersion,qty:x.baseQty,value:x.initialDirectValue,refs:x.receiptValuationRefs,businessDate:x.businessDate,original:x.originalPeriod,posting:x.postingPeriod});return true;},shuffleTargets:(t=val13Current())=>{t.targets.reverse();return true;}};
window.val13V398=val13Engine;
window.val13Engine=val13Engine;
})();
var val13Engine=window.val13Engine;

screenAliases["UIF-13"] = Object.assign(screenAliases["UIF-13"] || {}, {
  "SCR-087": "SCR-086",
  "SCR-088": "SCR-086",
});
{ const a = screenAliases[activeFlowId]?.[activeScreenId]; if (Array.isArray(a)) { activeFlowId = a[0]; activeScreenId = a[1]; } else if (a) activeScreenId = a; }

ownedFlows.add("UIF-13");

