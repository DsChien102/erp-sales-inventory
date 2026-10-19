/* BJ-14 — Tính và công bố giá vốn (UIF-14). Màn: SCR-072, SCR-074, SCR-077.
 *
 * Đã viết lại sạch (T7-P gói A5, 2026-10-17); tách đúng theo BJ ở A12 R7 (2026-10-19). Sửa BJ-14: sửa thẳng file này.
 * Màn dựng ở khối cuối (bản v461; 073 / 075 / 076 là đường cũ). Helper val14* gán trong khối chuẩn hoá v399.
 */
// UIF-14 / BJ-14 v1.5.0 — Cost run calculation and publication.
// Run is immutable once created; blockers/calculating are states of SCR-074.
// ============================================================================
const val14Runs=[
  {id:"COST-0826",label:"Tháng 08/2026",kind:"PERIOD_CLOSE",status:"READY_FOR_REVIEW",period:"08/2026",scope:"184 sản phẩm",cutoff:"31/08/2026 · 23:59",policyMethod:"PERIODIC",policyLabel:"Bình quân cuối kỳ",policyVersion:"Chính sách giá vốn",moving:{inventory:1242800000,cogs:488120000},periodic:{inventory:1245920000,cogs:486300000},cogsTrueUp:-1820000,endingAdjustment:3120000,effectiveAt:"01/09/2026 · 00:00",blockers:[],inputVersion:7,runVersion:3,supersedes:null},
  {id:"COST-0903",label:"Cập nhật 03/09/2026",kind:"AD_HOC",status:"DIRTY",period:"09/2026",scope:"3 sản phẩm",cutoff:"04/09/2026 · 10:00",policyMethod:"PERIODIC",policyLabel:"Bình quân cuối kỳ",policyVersion:"Chính sách giá vốn",moving:{inventory:186400000,cogs:52700000},periodic:{inventory:186180000,cogs:52920000},cogsTrueUp:220000,endingAdjustment:-220000,effectiveAt:"04/09/2026 · 10:00",blockers:[],inputVersion:4,runVersion:0,supersedes:"COST-0902"},
  {id:"COST-0901-B",label:"Tháng 09/2026",kind:"PERIOD_CLOSE",status:"BLOCKED",period:"09/2026",scope:"Toàn bộ sản phẩm",cutoff:"30/09/2026 · 23:59",policyMethod:"PERIODIC",policyLabel:"Bình quân cuối kỳ",policyVersion:"Chính sách giá vốn",moving:null,periodic:null,cogsTrueUp:0,endingAdjustment:0,effectiveAt:"01/10/2026 · 00:00",blockers:[{title:"2 dòng hàng còn chờ xác nhận giá",owner:"Định giá tồn kho"},{title:"1 đối soát chưa có kết quả cuối",owner:"Kiểm soát tồn kho"}],inputVersion:2,runVersion:1,supersedes:null}
];
let val14SelectedRunId="COST-0826",val14SetupKind="PERIOD_CLOSE",val14SetupPeriod="08/2026",val14SetupScope="Toàn bộ sản phẩm",val14SuccessorOf=null,val14PublishReviewVersion=null,val14LastResult=null,val14CalcTimer=null;
function val14Current(){return val14Runs.find(r=>r.id===val14SelectedRunId)||val14Runs[0];}
function val14Money(n){const v=Math.round(Number(n)||0);return `${v<0?"− ":""}${Math.abs(v).toLocaleString("vi-VN")} đ`;}
function val14StatusMeta(r){if(r.status==="READY_FOR_REVIEW")return ["Sẵn sàng công bố","success"];if(r.status==="BLOCKED")return ["Bị chặn","warning"];if(r.status==="DIRTY")return ["Cần tính lại","warning"];if(r.status==="CALCULATING")return ["Đang tính","info"];if(r.status==="PUBLISHED")return ["Đã công bố","success"];return ["Chưa tính","neutral"];}
function val14MethodCard(r){
  const selected=r.policyMethod;
  const rows=[["MOVING","Bình quân liên hoàn",r.moving],["PERIODIC","Bình quân cuối kỳ",r.periodic]].map(([id,label,x])=>`<div class="val14-method-row ${selected===id?'is-policy':''}" data-composed-from="VText,VBadge"><span class="val14-method-copy"><strong>${esc(label)}</strong><small>${selected===id?'Dùng để công bố theo chính sách':'Giữ để đối chiếu'}</small>${selected===id?`<span class="val14-policy-badge">${ds24Badge("Theo chính sách","Success")}</span>`:""}</span><span class="val14-method-values"><strong>${x?esc(val14Money(x.inventory)):"—"}</strong><small>Giá trị tồn cuối</small><small>Giá vốn xuất ${x?esc(val14Money(x.cogs)):"—"}</small></span></div>`).join("");
  return ds24GroupedCollection(rows,"valuation-method-collection val14-method-card","VText,VBadge");
}
function val14Blockers(r){
  const rows=r.blockers.map(b=>`<div class="val14-blocker-row" data-composed-from="DS v2 / Icon,VText"><span class="val14-blocker-icon">${icon("alertTriangle","icon--sm")}</span><span><strong>${esc(b.title)}</strong><small>Đang chờ: ${esc(b.owner)}</small></span></div>`).join("");
  return ds24GroupedCollection(rows,"valuation-blocker-collection val14-blocker-card","DS v2 / Icon,VText");
}
// Helper BJ-14 — một định nghĩa duy nhất, gán trong khối v399 bên dưới (cần biến cục bộ của khối).
let val14RunSummary, val14AdjustmentCard, val14CreateRun, val14Commit, val14ApplyInputChange;
// Chính sách giá vốn của tenant áp lên mọi lần tính (trước đây bọc val14CreateRun trong khối v461).
const BJ14_COST_POLICY=window.__VET45_TENANT_COST_POLICY__||{version:'MISSING',method:null,label:'Chưa cấu hình',periodCloseScopes:[]};
function bj14ApplyPolicy(r){try{val14EnrichRun(r,0);}catch(_){}r.policyMethod=BJ14_COST_POLICY.method;r.policyLabel=BJ14_COST_POLICY.label;r.policyVersion=BJ14_COST_POLICY.version;return r;}
function val14KindChoices(){
  const periodClose=val14SetupKind==="PERIOD_CLOSE";
  const row=(kind,title,desc,selected)=>`<button type="button" class="val14-choice-row${selected?' is-selected':''}" data-val14-kind="${kind}" data-ds-component="VRadio" data-figma-node="522:7410" data-ds-prop-state="${selected?'On':'Off'}" aria-pressed="${selected}"><span class="val14-radio-control" aria-hidden="true"><span></span></span><span class="val14-choice-copy"><strong>${esc(title)}</strong><small>${esc(desc)}</small></span></button>`;
  return `<div class="val14-choice-list" data-composed-from="VRadio">${row("PERIOD_CLOSE","Chốt kỳ","Tính toàn kỳ theo thời điểm chốt kế toán",periodClose)}${row("AD_HOC","Cập nhật trong kỳ","Chỉ tính phạm vi cần cập nhật",!periodClose)}</div>`;
}

/* chuẩn hoá + helper thắng (v399) */
(()=>{
const nowLabel="17/09/2026 · 08:41";
const productSeed=[
  {product:"Nobivac DHPPi",baseUom:"lọ",state:"CHANGED",oldCost:81000,newCost:81700,cogsDelta:-900000,endingDelta:1450000,official:"81.700 đ/lọ"},
  {product:"Amoxicillin 500mg",baseUom:"viên",state:"CHANGED",oldCost:12450,newCost:12380,cogsDelta:-920000,endingDelta:1670000,official:"12.380 đ/viên"},
  {product:"Găng tay khám",baseUom:"đôi",state:"NO_NEW_COST_BASIS",oldCost:3200,newCost:3200,cogsDelta:0,endingDelta:0,official:"Giữ 3.200 đ/đôi"}
];
function hashFor(r){return `RUN-${String(r.id).replace(/[^A-Z0-9]/gi,'').slice(-10)}-${r.runVersion||1}-${r.dirtyScopeVersion||1}`;}
function enrich(r,idx){
  r.runType=r.runType||r.kind;
  r.calculationPeriod=r.calculationPeriod||r.period;
  r.postingPeriod=r.postingPeriod||r.period;
  r.scopeOrigin=r.scopeOrigin||(r.kind==="AD_HOC"?"DIRTY_SCOPE":"PERIOD_CLOSE_POLICY");
  r.dirtyScopeVersion=r.dirtyScopeVersion||(r.kind==="AD_HOC"?3:1);
  r.dirtyScopeHash=r.dirtyScopeHash||`DIRTY-${r.period.replace('/','')}-${r.dirtyScopeVersion}`;
  r.dirtyCauseCount=r.dirtyCauseCount||(r.kind==="AD_HOC"?3:0);
  r.cutoffValuationSequence=r.cutoffValuationSequence||(12840+idx*100);
  r.productCount=r.productCount||(r.kind==="AD_HOC"?3:184);
  r.changedProductCount=r.changedProductCount||(r.status==="BLOCKED"?0:(r.kind==="AD_HOC"?2:37));
  r.productResults=r.productResults||productSeed.map((x,i)=>({...x,resultHash:`PCR-${r.period.replace('/','')}-${i+1}`}));
  r.productResultSetHash=r.productResultSetHash||`PCRSET-${r.period.replace('/','')}-${r.runVersion||1}`;
  r.runInputHash=r.runInputHash||hashFor(r);
  r.cogsTrueUp=Number(r.cogsTrueUp||0);
  r.endingAdjustment=Number(r.endingAdjustment||0);
  if(r.id==="COST-0826" && r.status!=="PUBLISHED") r.effectiveAt="Khi công bố";
  if(r.kind==="AD_HOC" && r.status!=="PUBLISHED") r.effectiveAt="Khi công bố";
  return r;
}
val14Runs.forEach(enrich);

function scopeLabel(r){return r.scopeOrigin==="DIRTY_SCOPE"?`${r.productCount} sản phẩm cần tính lại`:r.scope;}
function productRows(r){
  const rows=(r.productResults||[]).slice(0,3).map(x=>`<div class="v399-product-cost-row" data-composed-from="VText,VBadge"><span class="v399-product-copy"><strong>${esc(x.product)}</strong><small>${x.state==="NO_NEW_COST_BASIS"?'Không có căn cứ giá mới':`Giá đề xuất ${esc(x.official)}`}</small></span><span class="v399-product-delta"><strong>${esc(val14Money(x.cogsDelta+x.endingDelta))}</strong><small>${x.state==="NO_NEW_COST_BASIS"?'Không điều chỉnh':'Chênh lệch ròng'}</small></span></div>`).join('');
  return ds24GroupedCollection(rows,"v399-product-cost-list","VText,VBadge");
}
function v399PeriodFacts(r){
  return ds24InfoGroup("Phạm vi tính",`${ds24InfoRow("Kỳ tính",r.calculationPeriod)}${ds24InfoRow("Kỳ ghi nhận",r.postingPeriod)}${ds24InfoRow("Sản phẩm",String(r.productCount))}${ds24InfoRow("Có thay đổi",String(r.changedProductCount))}`,'valuation-info-group valuation-info-group--wrap');
}

val14RunSummary=function(r){
  enrich(r,0); const [label,tone]=val14StatusMeta(r);
  const context=ds24ContextStatusRow({title:r.label,subtitle:`Kỳ ${r.postingPeriod} · ${scopeLabel(r)}`,label,tone:valuationDsTone(tone),leading:null});
  const facts=ds24InfoGroup("Thông tin lần tính",`${ds24InfoRow("Thời điểm chốt",r.cutoff)}${ds24InfoRow("Phương pháp công bố",r.policyLabel)}${ds24InfoRow("Kỳ tính",r.calculationPeriod)}${ds24InfoRow("Kỳ ghi nhận",r.postingPeriod)}`,'valuation-info-group valuation-info-group--wrap val14-summary');
  return `${context}${facts}`;
};
val14AdjustmentCard=function(r,title="Chênh lệch cần ghi"){
  return ds24InfoGroup(title,`${ds24KeyValueRow("Giá vốn xuất",val14Money(r.cogsTrueUp),true)}${ds24KeyValueRow("Giá trị tồn cuối",val14Money(r.endingAdjustment),true)}${ds24InfoRow("Hiệu lực giá vốn",r.effectiveAt||"Khi công bố")}`,'valuation-info-group val14-adjustment');
};
val14CreateRun=function(){
  const id=`COST-${Date.now()}`; const base=val14SuccessorOf?val14Runs.find(x=>x.id===val14SuccessorOf):null;
  const isDirty=val14SetupKind==="AD_HOC" || !!base?.scopeOrigin&&base.scopeOrigin==="DIRTY_SCOPE";
  const run={id,label:val14SetupKind==="PERIOD_CLOSE"?`Tháng ${val14SetupPeriod}`:`Cập nhật ${nowLabel.split(' · ')[0]}`,kind:val14SetupKind,runType:val14SetupKind,status:"CALCULATING",period:val14SetupPeriod,calculationPeriod:val14SetupPeriod,postingPeriod:val14SetupPeriod,scope:isDirty?"Sản phẩm cần tính lại":val14SetupScope,scopeOrigin:isDirty?"DIRTY_SCOPE":"PERIOD_CLOSE_POLICY",cutoff:val14SetupKind==="PERIOD_CLOSE"?`Cuối kỳ ${val14SetupPeriod}`:nowLabel,policyMethod:base?.policyMethod||"PERIODIC",policyLabel:base?.policyLabel||"Bình quân cuối kỳ",policyVersion:base?.policyVersion||"Chính sách giá vốn",moving:{inventory:1243100000,cogs:488000000},periodic:{inventory:1246150000,cogs:486150000},cogsTrueUp:-1850000,endingAdjustment:3050000,effectiveAt:"Khi công bố",blockers:[],inputVersion:(base?.inputVersion||7)+1,runVersion:1,supersedes:base?.id||null,dirtyScopeVersion:(base?.dirtyScopeVersion||2)+1,dirtyCauseCount:isDirty?(base?.dirtyCauseCount||3):0,cutoffValuationSequence:(base?.cutoffValuationSequence||13000)+50,productCount:isDirty?(base?.productCount||3):184,changedProductCount:isDirty?2:38,productResults:productSeed.map((x,i)=>({...x,resultHash:`PCR-${Date.now()}-${i+1}`}))};
  enrich(run,0); val14Runs.unshift(run); val14SelectedRunId=id; val14PublishReviewVersion=null;
  if(val14CalcTimer)clearTimeout(val14CalcTimer); val14CalcTimer=setTimeout(()=>{run.status="READY_FOR_REVIEW";if(activeFlowId==="UIF-14"&&activeScreenId==="SCR-074")renderAppScreen();},120); return bj14ApplyPolicy(run);
};
val14ApplyInputChange=function(){const r=val14Current();r.inputVersion+=1;r.dirtyScopeVersion+=1;r.runInputHash=`${hashFor(r)}-STALE`;if(r.status==="READY_FOR_REVIEW")r.status="INPUT_CHANGED";return r.runInputHash;};
val14Commit=function(){
  const r=val14Current(); enrich(r,0); r.status="PUBLISHED";r.runVersion+=1;r.publishedAt=nowLabel;r.effectiveAt=nowLabel;
  const created=(r.productResults||[]).filter(x=>x.state!=="NO_NEW_COST_BASIS"&&x.newCost!==x.oldCost).length;
  val14LastResult={runId:r.id,period:r.period,calculationPeriod:r.calculationPeriod,postingPeriod:r.postingPeriod,scope:scopeLabel(r),method:r.policyLabel,effectiveAt:r.effectiveAt,cogsTrueUp:r.cogsTrueUp,endingAdjustment:r.endingAdjustment,reconciledProducts:r.productCount,changedProducts:r.changedProductCount,officialCostVersions:created,dirtyCausesCleared:r.scopeOrigin==="DIRTY_SCOPE"?r.dirtyCauseCount:0,runInputHash:r.runInputHash,productResultSetHash:r.productResultSetHash};return val14LastResult;
};
function val14EnrichRun(r, n){ return enrich(r, n); }
window.val14EnrichRun=val14EnrichRun;
})();
var val14EnrichRun=window.val14EnrichRun;

screenAliases["UIF-14"] = Object.assign(screenAliases["UIF-14"] || {}, {
  "SCR-073": "SCR-074",
  "SCR-075": "SCR-074",
  "SCR-076": "SCR-074",
});
{ const a = screenAliases[activeFlowId]?.[activeScreenId]; if (Array.isArray(a)) { activeFlowId = a[0]; activeScreenId = a[1]; } else if (a) activeScreenId = a; }

/* --- SCR-072 / 074 / 077 (bản v461) — BJ-14 --- */
(()=>{
  const {money, signed, row, heading, flat, keys, context, button, selectField, confirmSheet}=VAL_UI_461;
  let mode14='RESULT',publish14=false,compare14=false,productDetail14=false;
  if(typeof val14Runs!=='undefined')val14Runs.forEach(bj14ApplyPolicy);
  const scopeLabel14=r=>r.scopeOrigin==='DIRTY_SCOPE'?`${r.productCount||3} sản phẩm cần cập nhật`:r.scope;
  const methodResult=r=>r.policyMethod==='MOVING'?(r.moving||{}):(r.periodic||{});
  const compareResult=r=>r.policyMethod==='MOVING'?(r.periodic||{}):(r.moving||{});
  const compareLabel=r=>r.policyMethod==='MOVING'?'Bình quân cuối kỳ':'Bình quân liên hoàn';
  const policy14=r=>flat('Phương pháp',`${ds24InfoRow('Phương pháp áp dụng',r.policyLabel)}${ds24InfoRow('Chính sách','Theo chính sách của tổ chức')}`,'v460-policy');
  function setup14(r){
    const dirty=mode14==='DIRTY_SETUP',period=dirty?(r.postingPeriod||r.period):val14SetupPeriod;
    if(dirty)return `${flat('Phạm vi cần cập nhật',`${ds24InfoRow('Kỳ ghi nhận',period)}${ds24InfoRow('Phạm vi',scopeLabel14(r))}`)}${policy14(r)}`;
    const periodField=selectField('Kỳ','data-v461-val14-period',`<option ${val14SetupPeriod==='08/2026'?'selected':''}>08/2026</option><option ${val14SetupPeriod==='09/2026'?'selected':''}>09/2026</option>`), opts=BJ14_COST_POLICY.periodCloseScopes||[];
    if(opts.length===1)val14SetupScope=opts[0].label;
    const scopeOpts=[`<option value="" ${!val14SetupScope?'selected':''} disabled>Chọn phạm vi</option>`,...opts.map(x=>`<option value="${escapeAttribute(x.id)}" ${val14SetupScope===x.label?'selected':''}>${esc(x.label)}</option>`)].join('');
    const scope=opts.length===1?flat('Phạm vi',ds24InfoRow('Phạm vi',opts[0].label)):selectField('Phạm vi','data-v461-val14-scope',scopeOpts);
    return `${periodField}${scope}${policy14(r)}`;
  }
  function results14(r){const x=methodResult(r);return `${ds24SummaryCard('Kết quả sau tính',`${r.policyLabel} · ${scopeLabel14(r)}`,'data-ds-prop-tone="Neutral"')}${keys(`${ds24KeyValueRow('Giá trị tồn cuối',val14Money(x.inventory||0),true)}${ds24KeyValueRow('Giá vốn xuất',val14Money(x.cogs||0),true)}`,'v460-cost-total')}${heading('Thay đổi sẽ ghi khi công bố')}<p class="v460-helper">Chỉ phần chênh lệch dưới đây được ghi; chứng từ lịch sử không bị sửa.</p>${keys(`${ds24KeyValueRow('Điều chỉnh giá vốn xuất',signed(r.cogsTrueUp||0),true)}${ds24KeyValueRow('Điều chỉnh giá trị tồn',signed(r.endingAdjustment||0),true)}`,'v460-cost-delta')}`;}
  function comparison14(r){const x=compareResult(r);return `<details class="v430-details v460-details" ${compare14?'open':''} data-v461-compare><summary>Xem đối chiếu theo ${esc(compareLabel(r))}</summary><div class="v430-details__body">${flat(`${compareLabel(r)} · chỉ đối chiếu`,`${ds24KeyValueRow('Giá trị tồn cuối',val14Money(x.inventory||0))}${ds24KeyValueRow('Giá vốn xuất',val14Money(x.cogs||0))}`)}</div></details>`;}
  function products14(r){const all=r.productResults||[],rows=all.map(x=>row({title:x.product||x.name||'Sản phẩm',subtitle:x.state==='NO_NEW_COST_BASIS'?'Chưa có căn cứ giá vốn mới':`Giá vốn mới ${x.newCost!=null?`${money(x.newCost)}/${x.baseUom||'đơn vị cơ sở'}`:'—'}`,trailing:x.state==='NO_NEW_COST_BASIS'?ds24Badge('Không đổi','Neutral'):'',leading:null,type:'Status',interactive:false})).join('');if(!rows)return '';return `${heading('Kết quả theo sản phẩm',`${r.changedProductCount||0} có thay đổi`)}<details class="v430-details v460-details" ${productDetail14?'open':''} data-v461-products><summary>Xem kết quả theo sản phẩm</summary><div class="v430-details__body"><section class="ds24-list-stack v430-list">${rows}</section></div></details>`;}
  function publishSheet14(r){return confirmSheet({title:'Công bố giá vốn?',desc:'Kết quả đã rà soát sẽ có hiệu lực. Hệ thống chỉ ghi phần chênh lệch, không sửa chứng từ lịch sử.',body:`${flat('Phạm vi công bố',`${ds24InfoRow('Kỳ ghi nhận',r.postingPeriod||r.period)}${ds24InfoRow('Phạm vi',scopeLabel14(r))}${ds24InfoRow('Phương pháp',r.policyLabel)}`)}${keys(`${ds24KeyValueRow('Điều chỉnh giá vốn xuất',signed(r.cogsTrueUp||0),true)}${ds24KeyValueRow('Điều chỉnh giá trị tồn',signed(r.endingAdjustment||0),true)}`)}`,confirmLabel:'Công bố giá vốn',confirmAttr:'data-v461-val14-publish',closeAttr:'data-v461-val14-publish-close'});}
  function workMeta14(r){bj14ApplyPolicy(r);if(r.status==='DIRTY')return {title:'Cập nhật giá vốn',subtitle:`${r.productCount||3} sản phẩm · có thay đổi giá trị`,label:'Cần tính lại',tone:'Warning'};if(r.status==='READY_FOR_REVIEW')return {title:`Chốt giá vốn ${r.period}`,subtitle:`Đã tính · ${r.productCount||r.scope} · chờ công bố`,label:'Sẵn sàng',tone:'Success'};if(r.status==='BLOCKED')return {title:`Chốt giá vốn ${r.period}`,subtitle:`${r.blockers?.length||0} vấn đề cần xử lý`,label:'Bị chặn',tone:'Warning'};return {title:r.label,subtitle:scopeLabel14(r),label:'Đang xử lý',tone:'Neutral'};}
  function render072BJ14(state){if(activeFlowId!=='UIF-14')return renderGeneric(screens.find(s=>s.id==='SCR-072'),state);if(state==='LOADING')return appShell({title:'Công việc giá vốn',body:loadingBody(),centered:true,back:false});if(state==='PERMISSION_DENIED')return appShell({title:'Công việc giá vốn',body:deniedBody(),centered:true,back:false});const rows=val14Runs.filter(r=>r.status!=='PUBLISHED').map(r=>{const m=workMeta14(r);return row({title:m.title,subtitle:m.subtitle,trailing:ds24Badge(m.label,m.tone),leading:null,type:'Navigation',attrs:`data-v461-val14-run="${r.id}"`});}).join('');return appShell({title:'Công việc giá vốn',body:rows?`<section class="ds24-list-stack v430-list">${rows}</section>`:ioEmpty('Không có công việc giá vốn','Chưa có phạm vi cần cập nhật hoặc chốt kỳ.'),back:false,actions:primaryFooter('Chốt kỳ','data-v461-val14-close-period')});}
  function render074BJ14(state){if(activeFlowId!=='UIF-14')return renderGeneric(screens.find(s=>s.id==='SCR-074'),state);const r=bj14ApplyPolicy(val14Current());if(state==='PERMISSION_DENIED')return appShell({title:'Tính và rà soát giá vốn',body:deniedBody(),centered:true});if(state==='INPUT_CHANGED'||r.status==='INPUT_CHANGED')return appShell({title:'Tính và rà soát giá vốn',body:`${vBanner('warning','Dữ liệu đầu vào đã thay đổi','Kết quả cũ được giữ để truy vết nhưng không còn đủ điều kiện công bố.')}${policy14(r)}`,actions:primaryFooter('Tạo lần tính kế tiếp','data-v461-val14-successor')});if(mode14==='DIRTY_SETUP'||mode14==='PERIOD_CLOSE_SETUP'){const noScope=mode14==='PERIOD_CLOSE_SETUP'&&(BJ14_COST_POLICY.periodCloseScopes||[]).length>1&&!val14SetupScope;return appShell({title:mode14==='DIRTY_SETUP'?'Cập nhật giá vốn':'Chốt giá vốn kỳ',body:setup14(r),actions:primaryFooter(mode14==='DIRTY_SETUP'?'Tính lại giá vốn':'Tính giá vốn','data-v461-val14-calculate',noScope)});}if(r.status==='CALCULATING'||state==='PROCESSING')return appShell({title:'Tính và rà soát giá vốn',body:ioResult('Đang tính giá vốn','Có thể rời màn hình. Kết quả được lưu trong cùng lần tính.',[['Kỳ ghi nhận',r.postingPeriod||r.period],['Phạm vi',scopeLabel14(r)]],'info'),centered:true});if(r.status==='BLOCKED'||state==='BLOCKED'){const blockers=(r.blockers||[]).map(b=>context(b.title,`Đang chờ: ${b.owner}`,'Cần xử lý','Warning')).join('');return appShell({title:'Tính và rà soát giá vốn',body:`${vBanner('warning','Chưa thể chốt giá vốn','Xử lý các vấn đề dưới đây trước khi công bố.')}${policy14(r)}${heading('Cần xử lý',`${r.blockers?.length||0} vấn đề`)}<section class="ds24-list-stack v430-list">${blockers}</section>`});}const body=`${policy14(r)}${results14(r)}${comparison14(r)}${products14(r)}${publish14?publishSheet14(r):''}`;return appShell({title:'Tính và rà soát giá vốn',body,actions:primaryFooter('Công bố giá vốn','data-v461-val14-open-publish',r.status!=='READY_FOR_REVIEW')});}
  function render077BJ14(state){if(activeFlowId!=='UIF-14')return renderGeneric(screens.find(s=>s.id==='SCR-077'),state);const r=bj14ApplyPolicy(val14Current()),res=val14LastResult||{runId:r.id,postingPeriod:r.postingPeriod||r.period,method:r.policyLabel,effectiveAt:r.effectiveAt,cogsTrueUp:r.cogsTrueUp,endingAdjustment:r.endingAdjustment,reconciledProducts:r.productCount||0,officialCostVersions:(r.productResults||[]).filter(x=>x.state!=='NO_NEW_COST_BASIS'&&x.newCost!==x.oldCost).length};if(state==='PROCESSING')return appShell({title:'Kết quả công bố giá vốn',body:loadingBody(),centered:true,back:false});if(state==='UNKNOWN'){const attrs=`data-v350-action="handoff-unknown" data-source-flow="UIF-14" data-operation="${escapeAttribute(res.runId||r.id)}" data-scope="${escapeAttribute(res.postingPeriod||r.period)}"`;return appShell({title:'Đang xác minh kết quả',body:ioResult('Chưa xác định giá vốn đã được công bố hay chưa','Không gửi lại lệnh công bố. Chuyển đúng lần này sang xác minh kết quả.',[['Lần tính',res.runId||r.id],['Trạng thái','Đang xác minh']],'warning'),centered:true,back:false,actions:primaryFooter('Chuyển sang xác minh',attrs)});}if(state==='REJECTED_EXECUTION')return appShell({title:'Kết quả công bố giá vốn',body:ioResult('Chưa công bố giá vốn','Không có điều chỉnh hoặc phiên bản giá vốn mới.',[['Kỳ ghi nhận',res.postingPeriod||r.period],['Tác động','Không thay đổi']],'warning'),centered:true,back:false,actions:primaryFooter('Về công việc giá vốn','data-v461-val14-list')});const body=`<div class="io-result">${resultHero('Đã công bố giá vốn','Phần chênh lệch đã được ghi và giá vốn chính thức mới đã có hiệu lực.')}${flat('Kết quả',`${ds24InfoRow('Kỳ ghi nhận',res.postingPeriod||r.period)}${ds24InfoRow('Phương pháp',res.method||r.policyLabel)}${ds24InfoRow('Sản phẩm đã đối soát',String(res.reconciledProducts||r.productCount||0))}${ds24InfoRow('Sản phẩm có giá vốn mới',String(res.officialCostVersions??0))}${ds24InfoRow('Hiệu lực',res.effectiveAt||r.effectiveAt||'—')}${ds24KeyValueRow('Điều chỉnh giá vốn xuất',signed(res.cogsTrueUp||0),true)}${ds24KeyValueRow('Điều chỉnh giá trị tồn',signed(res.endingAdjustment||0),true)}`)}</div>`;return appShell({title:'Kết quả công bố giá vốn',body,centered:true,back:false,actions:primaryFooter('Về công việc giá vốn','data-v461-val14-list')});}

  window.addEventListener('change',event=>{
    if(activeFlowId==='UIF-14'&&event.target.matches('[data-v461-val14-period]')){event.stopImmediatePropagation();val14SetupPeriod=event.target.value;return renderAppScreen();}
    if(activeFlowId==='UIF-14'&&event.target.matches('[data-v461-val14-scope]')){event.stopImmediatePropagation();const opt=(BJ14_COST_POLICY.periodCloseScopes||[]).find(x=>x.id===event.target.value);val14SetupScope=opt?.label||'';return renderAppScreen();}
  },true);
  window.addEventListener('click',event=>{
    let el;
    if(activeFlowId==='UIF-14'){
      if((el=event.target.closest('[data-v461-val14-run]'))){event.preventDefault();event.stopImmediatePropagation();val14SelectedRunId=el.dataset.v461Val14Run;const r=bj14ApplyPolicy(val14Current());publish14=false;compare14=false;productDetail14=false;if(r.status==='DIRTY'){val14SetupKind='AD_HOC';val14SetupPeriod=r.period;val14SetupScope='Sản phẩm cần tính lại';val14SuccessorOf=r.id;mode14='DIRTY_SETUP';}else{mode14='RESULT';stateByScreen['SCR-074']=r.status==='BLOCKED'?'BLOCKED':'READY';}return navigate('SCR-074');}
      if((el=event.target.closest('[data-v461-val14-close-period]'))){event.preventDefault();event.stopImmediatePropagation();val14SuccessorOf=null;val14SetupKind='PERIOD_CLOSE';val14SetupScope=(BJ14_COST_POLICY.periodCloseScopes||[]).length===1?BJ14_COST_POLICY.periodCloseScopes[0].label:'';mode14='PERIOD_CLOSE_SETUP';return navigate('SCR-074');}
      if((el=event.target.closest('[data-v461-val14-calculate]'))){event.preventDefault();event.stopImmediatePropagation();if(mode14==='PERIOD_CLOSE_SETUP'&&(BJ14_COST_POLICY.periodCloseScopes||[]).length>1&&!val14SetupScope)return;val14SetupKind=mode14==='DIRTY_SETUP'?'AD_HOC':'PERIOD_CLOSE';const run=val14CreateRun();bj14ApplyPolicy(run);mode14='RESULT';stateByScreen['SCR-074']='READY';return renderAppScreen();}
      if((el=event.target.closest('[data-v461-compare] summary'))){compare14=!compare14;return;}
      if((el=event.target.closest('[data-v461-products] summary'))){productDetail14=!productDetail14;return;}
      if((el=event.target.closest('[data-v461-val14-open-publish]'))){event.preventDefault();event.stopImmediatePropagation();const r=bj14ApplyPolicy(val14Current());if(r.status!=='READY_FOR_REVIEW')return;val14PublishReviewVersion=r.runInputHash||String(r.inputVersion);publish14=true;return renderAppScreen();}
      if((el=event.target.closest('[data-v461-val14-publish-close]'))){event.preventDefault();event.stopImmediatePropagation();publish14=false;return renderAppScreen();}
      if((el=event.target.closest('[data-v461-val14-publish]'))){event.preventDefault();event.stopImmediatePropagation();const r=bj14ApplyPolicy(val14Current());if(String(val14PublishReviewVersion)!==String(r.runInputHash||r.inputVersion)){r.status='INPUT_CHANGED';publish14=false;stateByScreen['SCR-074']='INPUT_CHANGED';return renderAppScreen();}val14Commit();publish14=false;stateByScreen['SCR-077']='COMPLETED';return navigate('SCR-077');}
      if((el=event.target.closest('[data-v461-val14-successor]'))){event.preventDefault();event.stopImmediatePropagation();const r=bj14ApplyPolicy(val14Current());val14SuccessorOf=r.id;val14SetupKind=r.kind;val14SetupPeriod=r.period;val14SetupScope=r.scopeOrigin==='DIRTY_SCOPE'?scopeLabel14(r):((BJ14_COST_POLICY.periodCloseScopes||[]).some(x=>x.label===r.scope)?r.scope:((BJ14_COST_POLICY.periodCloseScopes||[]).length===1?BJ14_COST_POLICY.periodCloseScopes[0].label:''));mode14=r.scopeOrigin==='DIRTY_SCOPE'?'DIRTY_SETUP':'PERIOD_CLOSE_SETUP';return renderAppScreen();}
      if((el=event.target.closest('[data-v461-val14-list]'))){event.preventDefault();event.stopImmediatePropagation();mode14='RESULT';publish14=false;return navigate('SCR-072');}
    }
  },true);
  Object.assign(renderers, {
    'SCR-072': render072BJ14,
    'SCR-073': render074BJ14,
    'SCR-074': render074BJ14,
    'SCR-075': render074BJ14,
    'SCR-076': render074BJ14,
    'SCR-077': render077BJ14,
  });

  // v350 dirty-scope chọn run DIRTY nhưng không set mode — cần DIRTY_SETUP để hiện nút Tính lại.
  if (activeFlowId === "UIF-14" && entryMode === "dirty-scope") {
    mode14 = "DIRTY_SETUP";
    const dirty = val14Runs.find((r) => r.status === "DIRTY");
    if (dirty) {
      val14SelectedRunId = dirty.id;
      val14SetupKind = "AD_HOC";
      val14SetupPeriod = dirty.period;
      val14SetupScope = "Sản phẩm cần tính lại";
      val14SuccessorOf = dirty.id;
    }
  }
})();



onEntry["UIF-14:dirty-scope"] = () => {
  if (typeof val14Runs === "undefined") return;
  const dirty = val14Runs.find((r) => r.status === "DIRTY");
  if (!dirty) return;
  val14SelectedRunId = dirty.id;
  val14SetupKind = dirty.kind;
  val14SetupPeriod = dirty.period;
  val14SetupScope = "Sản phẩm cần tính lại";
  val14SuccessorOf = dirty.id;
};
