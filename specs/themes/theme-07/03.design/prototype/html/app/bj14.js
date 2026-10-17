/* BJ-14 — Tính và công bố giá vốn (UIF-14). Màn: SCR-072, SCR-074, SCR-077.
 *
 * Đã viết lại sạch (T7-P gói A5, 2026-10-17). Sửa BJ-14: sửa thẳng file này.
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
function val14RunSummary(r){
  const [label,tone]=val14StatusMeta(r);
  const context=ds24ContextStatusRow({title:r.label,subtitle:`Kỳ ${r.period} · ${r.scope}`,label,tone:valuationDsTone(tone),leading:null});
  const facts=ds24InfoGroup("Thông tin lần tính",`${ds24InfoRow("Thời điểm chốt",r.cutoff)}${ds24InfoRow("Phương pháp công bố",r.policyLabel)}${ds24InfoRow("Chính sách",r.policyVersion)}`,"valuation-info-group valuation-info-group--wrap val14-summary");
  return `${context}${facts}`;
}
function val14AdjustmentCard(r,title="Điều chỉnh dự kiến"){
  return ds24InfoGroup(title,`${ds24KeyValueRow("Giá vốn xuất",val14Money(r.cogsTrueUp),true)}${ds24KeyValueRow("Giá trị tồn cuối",val14Money(r.endingAdjustment),true)}${ds24InfoRow("Hiệu lực",r.effectiveAt)}`,"valuation-info-group val14-adjustment");
}
function val14KindChoices(){
  const periodClose=val14SetupKind==="PERIOD_CLOSE";
  const row=(kind,title,desc,selected)=>`<button type="button" class="val14-choice-row${selected?' is-selected':''}" data-val14-kind="${kind}" data-ds-component="VRadio" data-figma-node="522:7410" data-ds-prop-state="${selected?'On':'Off'}" aria-pressed="${selected}"><span class="val14-radio-control" aria-hidden="true"><span></span></span><span class="val14-choice-copy"><strong>${esc(title)}</strong><small>${esc(desc)}</small></span></button>`;
  return `<div class="val14-choice-list" data-composed-from="VRadio">${row("PERIOD_CLOSE","Chốt kỳ","Tính toàn kỳ theo thời điểm chốt kế toán",periodClose)}${row("AD_HOC","Cập nhật trong kỳ","Chỉ tính phạm vi cần cập nhật",!periodClose)}</div>`;
}
function val14CreateRun(){const id=`COST-${Date.now()}`;const base=val14SuccessorOf?val14Runs.find(x=>x.id===val14SuccessorOf):null;const run={id,label:val14SetupKind==="PERIOD_CLOSE"?`Tháng ${val14SetupPeriod}`:`Cập nhật ${new Date().toLocaleDateString("vi-VN")}`,kind:val14SetupKind,status:"CALCULATING",period:val14SetupPeriod,scope:val14SetupScope,cutoff:val14SetupKind==="PERIOD_CLOSE"?`Cuối kỳ ${val14SetupPeriod}`:"04/09/2026 · 14:30",policyMethod:base?.policyMethod||"PERIODIC",policyLabel:base?.policyLabel||"Bình quân cuối kỳ",policyVersion:base?.policyVersion||"Chính sách giá vốn",moving:{inventory:1243100000,cogs:488000000},periodic:{inventory:1246150000,cogs:486150000},cogsTrueUp:-1850000,endingAdjustment:3050000,effectiveAt:val14SetupKind==="PERIOD_CLOSE"?"01/09/2026 · 00:00":"04/09/2026 · 14:30",blockers:[],inputVersion:(base?.inputVersion||7)+1,runVersion:1,supersedes:base?.id||val14SuccessorOf};val14Runs.unshift(run);val14SelectedRunId=id;val14PublishReviewVersion=null;if(val14CalcTimer)clearTimeout(val14CalcTimer);val14CalcTimer=setTimeout(()=>{run.status="READY_FOR_REVIEW";if(activeFlowId==="UIF-14"&&activeScreenId==="SCR-074")renderAppScreen();},120);return run;}
function val14Commit(){const r=val14Current();r.status="PUBLISHED";r.runVersion+=1;val14LastResult={period:r.period,scope:r.scope,method:r.policyLabel,effectiveAt:r.effectiveAt,cogsTrueUp:r.cogsTrueUp,endingAdjustment:r.endingAdjustment};return val14LastResult;}
function val14ApplyInputChange(){const r=val14Current();r.inputVersion+=1;if(r.status==="READY_FOR_REVIEW")r.status="INPUT_CHANGED";return r.inputVersion;}

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
  if(val14CalcTimer)clearTimeout(val14CalcTimer); val14CalcTimer=setTimeout(()=>{run.status="READY_FOR_REVIEW";if(activeFlowId==="UIF-14"&&activeScreenId==="SCR-074")renderAppScreen();},120); return run;
};
val14ApplyInputChange=function(){const r=val14Current();r.inputVersion+=1;r.dirtyScopeVersion+=1;r.runInputHash=`${hashFor(r)}-STALE`;if(r.status==="READY_FOR_REVIEW")r.status="INPUT_CHANGED";return r.runInputHash;};
val14Commit=function(){
  const r=val14Current(); enrich(r,0); r.status="PUBLISHED";r.runVersion+=1;r.publishedAt=nowLabel;r.effectiveAt=nowLabel;
  const created=(r.productResults||[]).filter(x=>x.state!=="NO_NEW_COST_BASIS"&&x.newCost!==x.oldCost).length;
  val14LastResult={runId:r.id,period:r.period,calculationPeriod:r.calculationPeriod,postingPeriod:r.postingPeriod,scope:scopeLabel(r),method:r.policyLabel,effectiveAt:r.effectiveAt,cogsTrueUp:r.cogsTrueUp,endingAdjustment:r.endingAdjustment,reconciledProducts:r.productCount,changedProducts:r.changedProductCount,officialCostVersions:created,dirtyCausesCleared:r.scopeOrigin==="DIRTY_SCOPE"?r.dirtyCauseCount:0,runInputHash:r.runInputHash,productResultSetHash:r.productResultSetHash};return val14LastResult;
};
function val14EnrichRun(r, n){ return enrich(r, n); }
window.__VET45_V399__={version:"3.9.9",decisions:[164,165,166,167,168,169,170],enrichRun:enrich};
window.val14EnrichRun=val14EnrichRun;
})();
var val14EnrichRun=window.val14EnrichRun;

screenAliases["UIF-14"] = Object.assign(screenAliases["UIF-14"] || {}, {
  "SCR-073": "SCR-074",
  "SCR-075": "SCR-074",
  "SCR-076": "SCR-074",
});
{ const a = screenAliases[activeFlowId]?.[activeScreenId]; if (Array.isArray(a)) { activeFlowId = a[0]; activeScreenId = a[1]; } else if (a) activeScreenId = a; }

/* --- winning form/result renderers + listeners (from v461) --- */
(()=>{

  if(typeof renderers==='undefined') return;
  const money=n=>`${Number(n||0)<0?'− ':''}${Math.abs(Math.round(Number(n)||0)).toLocaleString('vi-VN')} đ`;
  const signed=n=>`${Number(n||0)>0?'+ ':Number(n||0)<0?'− ':''}${Math.abs(Math.round(Number(n)||0)).toLocaleString('vi-VN')} đ`;
  const pct=n=>`${(Number(n||0)*100).toLocaleString('vi-VN',{maximumFractionDigits:1})}%`;
  const row=args=>ds24ListRow({...args,density:args.density||'Compact'});
  const heading=(t,m='')=>ds24SectionTitle(t,m);
  const flat=(title,rows,extra='')=>`<section class="v430-flat v460-flat ${extra}" data-composed-from="DS v2 / Info Row,DS v2 / Key-value Row">${title?heading(title):''}<div class="v430-flat__rows">${rows}</div></section>`;
  const keys=(rows,extra='')=>`<div class="v430-key-stack v460-key-stack ${extra}" data-composed-from="DS v2 / Key-value Row">${rows}</div>`;
  const context=(title,subtitle,badge='',tone='Neutral')=>row({title,subtitle,trailing:badge?ds24Badge(badge,tone):'',leading:null,type:'Status',interactive:false});
  const button=(label,attrs,kind='primary',disabled=false)=>`<button type="button" class="button button--${kind}" ${attrs} data-ds-component="VButton" data-figma-node="521:529" ${disabled?'disabled':''}>${esc(label)}</button>`;
  const linkButton=(label,attrs)=>`<button type="button" class="v430-link" ${attrs} data-ds-component="DS v2 / Link">${esc(label)}</button>`;
  const textField=(label,attrs,value='',helper='',required=false)=>`<label class="v430-field" data-ds-component="VTextField" data-figma-node="522:7186"><span>${esc(label)}${required?' <b>*</b>':''}</span><input class="v430-control" ${attrs} value="${escapeAttribute(value)}"/>${helper?`<small>${esc(helper)}</small>`:''}<small class="v430-field-error" hidden></small></label>`;
  const moneyField=(label,attrs,value='',helper='',required=false)=>`<label class="v430-field" data-ds-component="VMoneyField" data-figma-node="522:7322"><span>${esc(label)}${required?' <b>*</b>':''}</span><div class="v430-money"><input class="v430-control" inputmode="decimal" type="number" ${attrs} value="${escapeAttribute(value)}"/><span>đ</span></div>${helper?`<small>${esc(helper)}</small>`:''}<small class="v430-field-error" hidden></small></label>`;
  const textarea=(label,attrs,value='',helper='',required=false)=>`<label class="v430-field" data-ds-component="VTextarea" data-figma-node="522:7212"><span>${esc(label)}${required?' <b>*</b>':''}</span><textarea class="v430-control v430-textarea" rows="3" ${attrs}>${esc(value)}</textarea>${helper?`<small>${esc(helper)}</small>`:''}<small class="v430-field-error" hidden></small></label>`;
  const selectField=(label,attrs,options)=>`<label class="v430-field" data-ds-component="VSelect" data-figma-node="522:7291"><span>${esc(label)}</span><select class="v430-control" ${attrs}>${options}</select></label>`;
  const formSheet=({title,intro,body,saveLabel='Lưu',saveAttr,closeAttr})=>`<div class="v430-overlay" data-v461-overlay><div class="v430-overlay__backdrop" ${closeAttr}></div><section class="v430-form-sheet" data-ds-component="DS v2 / Form Sheet" data-figma-node="1353:6355" role="dialog" aria-modal="true" aria-label="${escapeAttribute(title)}"><div class="v430-sheet-handle-area"><div class="v430-sheet-handle"></div></div><header class="v430-sheet-header"><h2>${esc(title)}</h2><button type="button" class="v430-sheet-close" ${closeAttr} aria-label="Đóng" data-ds-component="DS v2 / Icon Button" data-figma-node="4431:10317">${icon('close','icon--sm')}</button></header>${intro?`<p class="v430-sheet-intro">${esc(intro)}</p>`:''}<div class="v430-form-sheet__body">${body}</div><footer class="v430-sheet-footer" data-ds-component="DS v2 / Sticky Footer" data-figma-node="549:927"><button type="button" class="button button--primary" ${saveAttr} data-ds-component="VButton">${esc(saveLabel)}</button></footer></section></div>`;
  const confirmSheet=({title,desc,body,confirmLabel,confirmAttr,closeAttr})=>`<div class="sheet-backdrop ds24-overlay v430-confirm-overlay"><div class="v430-confirm-backdrop" ${closeAttr}></div><section class="ds24-confirmation v430-confirmation" data-ds-component="DS v2 / Confirmation Sheet" data-figma-node="550:1058" role="dialog" aria-modal="true" aria-label="${escapeAttribute(title)}"><div class="ds24-confirmation__handle"></div><h3 class="vet45-text-style-4">${esc(title)}</h3><p class="vet45-text-style-6">${esc(desc)}</p>${body}<div class="ds24-confirmation__actions"><button type="button" class="ds24-button ds24-button--secondary" ${closeAttr} data-ds-component="VButton">Quay lại</button><button type="button" class="ds24-button ds24-button--primary" ${confirmAttr} data-ds-component="VButton">${esc(confirmLabel)}</button></div></section></div>`;

  // ------------------------------------------------------------------
  // SCR-008 — only remove architecture copy and show warehouse disabled.
  // ------------------------------------------------------------------
// ------------------------------------------------------------------
  // BJ03
  // ------------------------------------------------------------------
  let basisSheetGroup=null, basisDraft=null;
  const qty=g=>(g.slices||[]).filter(s=>Number(s.pendingQty||0)>0).reduce((n,s)=>n+Number(s.pendingQty||0),0);
  const pendingGroups=r=>(r.groups||[]).filter(g=>qty(g)>0);
  const selectedGroups=(r=val03Current())=>pendingGroups(r).filter(g=>(g.slices||[]).some(s=>s.selected&&Number(s.pendingQty||0)>0));
  const isQuick=r=>r.v313EntryType==='QUICK'||r.id==='VAL03-R2'||r.id==='VAL03-R3';
  const groupState=(r,g)=>{const st=val03EvidenceState(g);if(st==='READY')return 'READY';if(st==='CONFLICT')return isQuick(r)?'DIRECT_CONFLICT':'COMMERCIAL_CONFLICT';return isQuick(r)?'DIRECT_MISSING':'COMMERCIAL_MISSING';};
  const selectGroup=(g,on)=>(g.slices||[]).filter(s=>Number(s.pendingQty||0)>0).forEach(s=>{s.selected=on;s.selectedQty=s.pendingQty;s.partialOpen=false;});
  const actualUnit=g=>Number(val03Calc(g)?.unitActual||0);
  const breakdown=g=>{const s=val03Source(g),c=val03Calc(g);if(!s||!c)return '';const purchase=Number(s.unitPrice||0)*Number(s.fxRate||1);return keys(`${ds24KeyValueRow('Giá mua',`${money(purchase)}/${g.uom}`)}${s.unitLineDiscount?ds24KeyValueRow('Chiết khấu dòng',`− ${money(s.unitLineDiscount)}/${g.uom}`):''}${s.unitDocDiscount?ds24KeyValueRow('Chiết khấu chứng từ',`− ${money(s.unitDocDiscount)}/${g.uom}`):''}${s.unitKnownCost?ds24KeyValueRow('Chi phí mua đã biết',`+ ${money(s.unitKnownCost)}/${g.uom}`):''}${s.unitNonDeductibleVat?ds24KeyValueRow('Thuế/phí tính vào giá trị',`+ ${money(s.unitNonDeductibleVat)}/${g.uom}`):''}${ds24KeyValueRow('Đơn giá ghi nhận ban đầu',`${money(c.unitActual)}/${g.uom}`,true)}`);};
  function groupHtml(r,g){
    const st=groupState(r,g),selected=selectedGroups(r).includes(g),pending=qty(g),base=`${pending} ${g.uom} đang chờ${g.tracking==='LOT'?` · ${(g.slices||[]).filter(s=>Number(s.pendingQty||0)>0).length} lô`:''}`;
    if(st==='READY'){
      const s=val03Source(g),unit=actualUnit(g),subtitle=`${base} · ${money(unit)}/${g.uom}`;
      return `<section class="v460-task ${selected?'is-selected':''}">${row({title:g.name,subtitle,trailing:selected?icon('checkCircle','icon--sm'):'',leading:null,type:'Selection',state:selected?'Selected':'Default',attrs:`data-v461-val03-select="${g.id}"`})}${selected?`<div class="v460-task__detail">${flat('Căn cứ đang dùng',ds24InfoRow('Căn cứ',s?.label||'—'))}${breakdown(g)}</div>`:''}</section>`;
    }
    if(st==='COMMERCIAL_CONFLICT')return `<section class="v460-task">${context(g.name,base,'Cần đối chiếu','Warning')}<div class="v430-support">${vBanner('warning','Căn cứ mua hàng đang mâu thuẫn','Đối chiếu nguồn mua có thẩm quyền trước khi xác lập giá trị.')}</div></section>`;
    if(st==='COMMERCIAL_MISSING')return `<section class="v460-task">${context(g.name,base,'Cần căn cứ','Warning')}<div class="v430-support">${vBanner('warning','Chưa đủ căn cứ mua hàng','Công việc sẽ cập nhật khi nguồn mua có thẩm quyền cung cấp đủ giá trị.')}</div></section>`;
    if(st==='DIRECT_MISSING')return `<section class="v460-task">${context(g.name,base,'Chưa có căn cứ','Neutral')}<div class="v430-support"><p class="v430-helper">Chưa có nguồn mua cấu trúc đủ dùng. Kế toán có thể lập căn cứ trực tiếp khi có đủ thông tin và bằng chứng.</p>${button('Thêm căn cứ giá',`data-v461-val03-add-basis="${g.id}"`,'secondary')}</div></section>`;
    if(st==='DIRECT_CONFLICT')return `<section class="v460-task">${context(g.name,base,'Cần kiểm tra','Warning')}<div class="v430-support">${vBanner('warning','Có nhiều căn cứ trực tiếp cần kiểm tra','Chỉ tiếp tục khi căn cứ sử dụng đã được xác định theo policy và có dấu vết rõ ràng.')}</div></section>`;
    return `<section class="v460-task">${context(g.name,base,'Cần kiểm tra','Warning')}</section>`;
  }
  const currencyCatalog=()=>window.__VET45_MONEY_CURRENCY_CATALOG__||[];
  const taxPolicy=()=>window.__VET45_TAX_TREATMENT_POLICY__||{recoverableRate:0,version:'UNSET'};
  const fxFor=currency=>window.__VET45_FX_SOURCE_FIXTURE__?.[currency]||null;
  function ensureBasisDraft(){if(!basisDraft)basisDraft={price:'',currency:'',taxMode:'',tax:'',source:'',date:'',ref:'',reason:''};return basisDraft;}
  function amountField(label,attrs,value='',helper='',required=false,currency=''){
    return `<label class="v430-field" data-ds-component="VMoneyField" data-figma-node="522:7322"><span>${esc(label)}${required?' <b>*</b>':''}</span><div class="v430-money"><input class="v430-control" inputmode="decimal" type="number" ${attrs} value="${escapeAttribute(value)}"/><span data-v461-currency-suffix>${esc(currency||'—')}</span></div>${helper?`<small>${esc(helper)}</small>`:''}<small class="v430-field-error" hidden></small></label>`;
  }
  function taxChoice(){const d=ensureBasisDraft();const item=(id,label,desc)=>`<button type="button" class="v460-choice ${d.taxMode===id?'is-selected':''}" data-v461-tax-mode="${id}" data-ds-component="VRadio" data-figma-node="522:7410" aria-pressed="${d.taxMode===id}"><span class="v460-choice__radio"><span></span></span><span><strong>${esc(label)}</strong><small>${esc(desc)}</small></span></button>`;return `<div class="v460-field-group"><span class="v460-field-label">Cách hiểu giá <b>*</b></span><div class="v460-choice-list">${item('INCLUDED','Đã gồm thuế','Đơn giá trên căn cứ đã bao gồm phần thuế của nguồn.')}${item('EXCLUDED','Chưa gồm thuế','Đơn giá trên căn cứ chưa bao gồm phần thuế của nguồn.')}</div><small class="v430-field-error" data-v461-taxmode-error hidden></small></div>`;}
  function basisForm(g){
    const d=ensureBasisDraft(), opts=[`<option value="">Chọn tiền tệ</option>`,...currencyCatalog().map(x=>`<option value="${escapeAttribute(x.id)}" ${d.currency===x.id?'selected':''}>${esc(x.label)}</option>`)].join('');
    const body=`${selectField('Tiền tệ *','data-v461-basis-currency',opts)}${amountField('Đơn giá mua','data-v461-basis-price min="0" step="0.01"',d.price,`Theo đơn vị ${g.uom}`,true,d.currency)}${taxChoice()}<div data-v461-tax-wrap ${d.taxMode==='EXCLUDED'?'':'hidden'}>${amountField('Thuế trên căn cứ','data-v461-basis-tax min="0" step="0.01"',d.tax,'Nhập số thuế ghi trên căn cứ nếu có; hệ thống áp chính sách thuế để xác định phần đi vào giá trị.',false,d.currency)}</div>${textField('Căn cứ giá từ đâu?','data-v461-basis-source placeholder="Ví dụ: Báo giá hoặc xác nhận giá của nhà cung cấp"',d.source,'Ghi nguồn nghiệp vụ tạo ra đơn giá, không phải tên tệp.',true)}${textField('Ngày căn cứ','data-v461-basis-date inputmode="numeric" placeholder="dd/mm/yyyy"',d.date,'',true)}${textField('Tham chiếu / bằng chứng','data-v461-basis-ref placeholder="Mã báo giá, email, ghi chú..."',d.ref)}${textarea('Lý do xác lập trực tiếp','data-v461-basis-reason placeholder="Nêu ngắn gọn lý do"',d.reason,'Bắt buộc vì chưa có nguồn mua cấu trúc đủ dùng.',true)}`;
    return formSheet({title:'Thêm căn cứ giá',intro:`${g.name} · Ghi đơn giá, tiền tệ, nguồn và ngày căn cứ.`,body,saveLabel:'Lưu căn cứ',saveAttr:'data-v461-val03-sheet="save"',closeAttr:'data-v461-val03-sheet="close"'});
  }
  function setError(root,sel,msg){const input=root.querySelector(sel),field=input?.closest('.v430-field');if(!input||!field)return null;input.classList.add('is-error');const e=field.querySelector('.v430-field-error');if(e){e.textContent=msg;e.hidden=false;}return input;}
  function syncBasisDraft(root){const d=ensureBasisDraft();d.price=String(root.querySelector('[data-v461-basis-price]')?.value||'');d.currency=String(root.querySelector('[data-v461-basis-currency]')?.value||'');d.tax=String(root.querySelector('[data-v461-basis-tax]')?.value||'');d.source=String(root.querySelector('[data-v461-basis-source]')?.value||'').trim();d.date=String(root.querySelector('[data-v461-basis-date]')?.value||'').trim();d.ref=String(root.querySelector('[data-v461-basis-ref]')?.value||'').trim();d.reason=String(root.querySelector('[data-v461-basis-reason]')?.value||'').trim();return d;}
  function saveBasis(groupId){
    const r=val03Current(),g=(r.groups||[]).find(x=>x.id===groupId),root=document.querySelector('.v430-form-sheet');if(!g||!root)return false;
    root.querySelectorAll('.is-error').forEach(x=>x.classList.remove('is-error'));root.querySelectorAll('.v430-field-error').forEach(x=>{x.hidden=true;x.textContent='';});
    const d=syncBasisDraft(root), price=Number(d.price||0), taxSource=d.taxMode==='EXCLUDED'?Number(d.tax||0):0, errs=[];
    if(!d.currency)errs.push(setError(root,'[data-v461-basis-currency]','Chọn tiền tệ.'));
    if(!(price>0))errs.push(setError(root,'[data-v461-basis-price]','Nhập đơn giá lớn hơn 0.'));
    if(!d.taxMode){const e=root.querySelector('[data-v461-taxmode-error]');if(e){e.textContent='Chọn cách hiểu giá.';e.hidden=false;}errs.push(root.querySelector('[data-v461-tax-mode]'));}
    if(!d.source)errs.push(setError(root,'[data-v461-basis-source]','Nhập căn cứ giá.'));
    if(!d.date)errs.push(setError(root,'[data-v461-basis-date]','Nhập ngày căn cứ.'));
    else if(!/^\d{2}\/\d{2}\/\d{4}$/.test(d.date))errs.push(setError(root,'[data-v461-basis-date]','Dùng định dạng dd/mm/yyyy.'));
    if(!d.reason)errs.push(setError(root,'[data-v461-basis-reason]','Nêu lý do xác lập trực tiếp.'));
    const fx=fxFor(d.currency);if(d.currency&&!fx)errs.push(setError(root,'[data-v461-basis-currency]','Chưa có dữ liệu quy đổi có thẩm quyền cho tiền tệ này.'));
    const first=errs.find(Boolean);if(first){first.focus?.();return false;}
    const recoverable=Math.max(0,Math.min(1,Number(taxPolicy().recoverableRate||0))), fxRate=Number(fx.rate||1), nonRecoverableTax=Math.round(taxSource*fxRate*(1-recoverable));
    const id=`DIRECT-${g.id}-${Date.now()}`, components=[{type:'PURCHASE_PRICE',label:'Giá mua',source:d.source,version:d.date,amount:price,currency:d.currency}];
    if(taxSource)components.push({type:'SOURCE_TAX',label:'Thuế trên căn cứ',source:d.source,version:d.date,amount:taxSource,currency:d.currency,taxPolicyVersion:taxPolicy().version,nonRecoverableAmountVnd:nonRecoverableTax});
    g.sources=[{id,label:`${d.source} · ${d.date}`,sourceAuthorityLabel:d.source,version:'v1',basisVersion:1,basisHash:`v461-${id}`,authoritativeValueHash:`v461-${Math.round(price*fxRate)+nonRecoverableTax}`,unitPrice:price,currency:d.currency,fxRate,fxSourceVersion:fx.version,fxLabel:'INTERNAL',unitLineDiscount:0,unitDocDiscount:0,unitKnownCost:0,unitNonDeductibleVat:nonRecoverableTax,components,evidenceRefs:d.ref?[d.ref]:[],provenance:components.map(c=>`${c.label} · ${c.source}`),directReason:d.reason,taxMode:d.taxMode,sourceDate:d.date,reference:d.ref,taxPolicyVersion:taxPolicy().version}];
    g.selectedSource=id;r.sourceVersion=Number(r.sourceVersion||0)+1;selectGroup(g,true);return true;
  }
  function canReview03(r=val03Current()){const a=selectedGroups(r);return a.length>0&&a.every(g=>groupState(r,g)==='READY');}
  function render015BJ03(state){
    if(activeFlowId!=='UIF-03')return renderGeneric(screens.find(s=>s.id==='SCR-015'),state);const r=val03Current();if(state==='PERMISSION_DENIED')return appShell({title:'Xác lập giá trị nhập ban đầu',body:deniedBody(),centered:true});
    const groups=pendingGroups(r).map(g=>groupHtml(r,g)).join(''),selected=selectedGroups(r),total=selected.reduce((n,g)=>n+Number(val03Calc(g)?.value||0),0),summary=selected.length?keys(`${ds24KeyValueRow(`${selected.length} sản phẩm đã chọn`,money(total),true)}`,'v460-selection-summary'):'';
    const body=`${context(r.receipt,`${r.supplier} · ${r.receivedAt}`,isQuick(r)?'Nhập nhanh':'Theo chứng từ','Neutral')}${groups||ioEmpty('Không còn hàng chờ giá trị','Các dòng thuộc phiếu nhận này đã được xử lý.')}${summary}${basisSheetGroup?basisForm((r.groups||[]).find(g=>g.id===basisSheetGroup)):''}`;
    return appShell({title:'Xác lập giá trị nhập ban đầu',body,actions:primaryFooter('Rà soát','data-v461-val03-review',!canReview03(r))});
  }
  function render017BJ03(state){ensureVal03ReviewFixture();
    if(activeFlowId!=='UIF-03')return renderGeneric(screens.find(s=>s.id==='SCR-017'),state);const r=val03Current();if(state==='PERMISSION_DENIED')return appShell({title:'Rà soát giá trị nhập ban đầu',body:deniedBody(),centered:true});const stale=state==='SOURCE_CHANGED'||val03ReviewSourceVersion==null||Number(val03ReviewSourceVersion)!==Number(r.sourceVersion);if(stale)return appShell({title:'Rà soát giá trị nhập ban đầu',body:`${vBanner('warning','Căn cứ đã thay đổi','Quay lại kiểm tra dữ liệu hiện hành trước khi xác nhận.')}${context(r.receipt,r.supplier)}`,actions:primaryFooter('Kiểm tra lại','data-v461-val03-back')});
    const groups=selectedGroups(r),total=groups.reduce((n,g)=>n+Number(val03Calc(g)?.value||0),0),items=groups.map(g=>{const c=val03Calc(g),s=val03Source(g);return `<section class="v460-review-item">${row({title:g.name,subtitle:`${c.qty} ${g.uom} · ${money(c.unitActual)}/${g.uom}`,trailing:`<strong class="v460-money-trailing">${money(c.value)}</strong>`,leading:null,type:'Status',interactive:false})}<details class="v430-details v460-details"><summary>Chi tiết căn cứ</summary><div class="v430-details__body">${flat('',ds24InfoRow('Căn cứ',s?.label||'—'))}${breakdown(g)}</div></details></section>`;}).join('');
    const body=`${context(r.receipt,`${r.supplier} · ${r.receivedAt}`)}${ds24SummaryCard('Tổng giá trị sẽ ghi',`${money(total)} · ${groups.length} sản phẩm`,'data-ds-prop-tone="Neutral"')}${heading('Sản phẩm sẽ ghi',`${groups.length} sản phẩm`)}<div class="v460-review-list">${items}</div>${linkButton('Chỉnh sửa căn cứ','data-v461-val03-back')}`;
    return appShell({title:'Rà soát giá trị nhập ban đầu',body,actions:primaryFooter('Xác nhận giá trị','data-v461-val03-confirm')});
  }
  function render019BJ03(state){ensureVal03ResultFixture();
    if(activeFlowId!=='UIF-03')return renderGeneric(screens.find(s=>s.id==='SCR-019'),state);const res=val03LastResult||{receipt:val03Current().receipt,groups:[],totalValue:0};if(state==='PROCESSING')return appShell({title:'Kết quả xác lập giá trị',body:loadingBody(),centered:true,back:false});if(state==='UNKNOWN'){const attrs=`data-v350-action="handoff-unknown" data-source-flow="UIF-03" data-operation="${escapeAttribute(res.operationId||'VAL-UNKNOWN')}" data-scope="${escapeAttribute(res.receipt||'')}"`;return appShell({title:'Đang xác minh kết quả',body:ioResult('Chưa xác định giá trị đã được ghi hay chưa','Không gửi lại lệnh xác nhận. Chuyển đúng lần xử lý này sang xác minh kết quả.',[['Phiếu nhận',res.receipt],['Trạng thái','Đang xác minh']],'warning'),centered:true,back:false,actions:primaryFooter('Chuyển sang xác minh',attrs)});}if(state==='REJECTED_EXECUTION')return appShell({title:'Kết quả xác lập giá trị',body:ioResult('Chưa ghi giá trị nhập ban đầu','Không có thay đổi. Kiểm tra lại căn cứ hiện hành.',[['Phiếu nhận',res.receipt],['Tác động','Không thay đổi']],'warning'),centered:true,back:false,actions:primaryFooter('Xem lại công việc','data-v461-val03-result-back')});
    const detail=(res.groups||[]).map(g=>row({title:g.name,subtitle:`${g.qty} ${g.uom} · ${money(g.unitInitial)}/${g.uom}`,trailing:`<strong class="v460-money-trailing">${money(g.value)}</strong>`,leading:null,type:'Status',interactive:false})).join(''),remaining=pendingGroups(val03Current()).length,summary=flat('Kết quả',`${ds24InfoRow('Phiếu nhận',res.receipt||'—')}${ds24InfoRow('Sản phẩm đã xác lập',String((res.groups||[]).length))}${ds24KeyValueRow('Tổng giá trị đã ghi',money(res.totalValue||0),true)}${ds24InfoRow('Giá vốn','Cần cập nhật')}`),details=detail?`<details class="v430-details v460-details"><summary>Xem chi tiết ${(res.groups||[]).length} sản phẩm</summary><div class="v430-details__body"><section class="ds24-list-stack v430-list">${detail}</section></div></details>`:'';
    const body=`<div class="io-result">${resultHero('Đã ghi giá trị nhập ban đầu','Giá trị đã được ghi cho đúng phạm vi; sản phẩm liên quan cần cập nhật giá vốn.')}${summary}${details}${remaining?vBanner('info','Còn hàng chờ giá trị',`${remaining} sản phẩm/dòng còn cần xử lý.`):''}</div>`;
    return appShell({title:'Kết quả xác lập giá trị',body,centered:true,back:false,actions:primaryFooter(remaining?'Tiếp tục xử lý':'Về danh sách',remaining?'data-v461-val03-result-back':'data-v461-val03-result-list')});
  }

  // ------------------------------------------------------------------
  // BJ13
  // ------------------------------------------------------------------
  let confirm13=false,detail13=false;
  const eligibleMethods=t=>(t.allowedMethods||[]).filter(m=>window.val13V398?.methodEligible?window.val13V398.methodEligible(t,m.id):true);
  const methodLabel=(t,id=t.selectedMethod)=>eligibleMethods(t).find(m=>m.id===id)?.label||(t.allowedMethods||[]).find(m=>m.id===id)?.label||'—';
  const selectedTargets13=t=>(t.targets||[]).filter(x=>t.targetScopeMode==='FIXED'||x.selected);
  function allocationRows13(t){const rows=val13Preview(t),sum=rows.reduce((n,x)=>n+Number(x.allocationMetric?.metricValue||0),0);return rows.map(x=>{const metric=Number(x.allocationMetric?.metricValue||0),metricText=t.selectedMethod==='FIXTURE_VALUE'?`${money(metric)} · ${pct(sum?metric/sum:0)}`:`${metric.toLocaleString('vi-VN')} ${x.allocationMetric?.unit||''} · ${pct(sum?metric/sum:0)}`;return `<div class="v460-allocation-row" data-composed-from="VText,DS v2 / Key-value Row"><div><strong>${esc(x.product)}</strong><small>${esc(x.receipt)} · ${x.qty} ${esc(x.uom)}${x.lot?` · Lô ${esc(x.lot)}`:''}</small><small>Căn cứ phân bổ: ${esc(metricText)}</small></div><strong>${esc(signed(x.allocatedAmount))}</strong></div>`;}).join('');}
  function methodControl13(t){const methods=eligibleMethods(t);if(methods.length<=1){const m=methods[0];if(!m)return flat('Cách phân bổ',ds24InfoRow('Phương pháp','Chưa có phương pháp hợp lệ'),'v460-method-readonly');const desc=m.id==='FIXTURE_VALUE'?'Phân bổ theo tỷ trọng giá trị nhập ban đầu của từng sản phẩm, trước các điều chỉnh phát sinh sau đó.':'Chỉ dùng khi toàn bộ phạm vi có chỉ tiêu lượng chuẩn cùng đơn vị và có thể so sánh.';return `<section class="v460-methods v460-method-readonly">${heading('Cách phân bổ')}<div class="v460-method-summary" data-composed-from="VText,DS v2 / Summary Card"><strong>${esc(m.label)}</strong><span>${esc(desc)}</span></div></section>`;}return `<section class="v460-methods">${heading('Cách phân bổ')}<div class="v460-choice-list">${methods.map(m=>`<button type="button" class="v460-choice ${t.selectedMethod===m.id?'is-selected':''}" data-v461-val13-method="${m.id}" data-ds-component="VRadio" aria-pressed="${t.selectedMethod===m.id}"><span class="v460-choice__radio"><span></span></span><span><strong>${esc(m.label)}</strong><small>${m.id==='FIXTURE_VALUE'?'Phân bổ theo tỷ trọng giá trị nhập ban đầu của từng sản phẩm':'Chỉ dùng khi toàn bộ phạm vi có chỉ tiêu lượng chuẩn cùng đơn vị'}</small></span></button>`).join('')}</div></section>`;}
  function period13(t){const targets=selectedTargets13(t),posting=[...new Set(targets.map(x=>x.postingPeriod).filter(Boolean))],original=[...new Set(targets.map(x=>x.originalPeriod).filter(Boolean))],moved=targets.some(x=>x.originalPeriod&&x.postingPeriod&&x.originalPeriod!==x.postingPeriod);if(!posting.length)return '';if(!moved&&posting.length===1)return flat('Kỳ ghi nhận',ds24InfoRow('Kỳ ghi điều chỉnh',posting[0]));const originalLabel=original.join(', ')||'—',postingLabel=posting.join(', ')||'—';return `${vBanner('info','Kỳ của hàng gốc đã khóa',`Điều chỉnh được ghi ở kỳ ${postingLabel}; kỳ ${originalLabel} vẫn được giữ để truy vết.`)}${flat('Kỳ ghi nhận',`${ds24InfoRow('Kỳ của hàng gốc',originalLabel)}${ds24InfoRow('Kỳ ghi điều chỉnh',postingLabel)}`)}`;}
  function render086BJ13(state){
    if(activeFlowId!=='UIF-13')return renderGeneric(screens.find(s=>s.id==='SCR-086'),state);const t=val13Current();if(state==='LOADING')return appShell({title:'Phân bổ điều chỉnh giá trị',body:loadingBody(),centered:true});if(state==='PERMISSION_DENIED')return appShell({title:'Phân bổ điều chỉnh giá trị',body:deniedBody(),centered:true});if(t.status==='WAITING')return appShell({title:'Phân bổ điều chỉnh giá trị',body:`${vBanner('info','Chưa thể xử lý',t.waitingOwner||'Đang chờ nguồn hoàn tất dữ liệu cần thiết.')}${context(t.sourceRef.replace(/ · dòng \d+$/,''),`${t.component} · ${t.supplier}`)}`});
    const methods=eligibleMethods(t);if(methods.length===1&&t.selectedMethod!==methods[0].id){t.selectedMethod=methods[0].id;val13PreviewHash=null;}const preview=val13Preview(t),total=preview.reduce((n,x)=>n+Number(x.allocatedAmount||0),0),targets=(t.targets||[]).map(x=>row({title:x.product,subtitle:`${x.receipt} · ${x.qty} ${x.uom}${x.lot?` · Lô ${x.lot}`:''}`,trailing:'',leading:null,type:'Status',interactive:false})).join(''),valid=val13CanPreview(t)&&preview.length>0;
    const source=`${context(t.sourceRef.replace(/ · dòng \d+$/,''),`${t.component} · ${t.supplier}`)}${keys(ds24KeyValueRow('Giá trị điều chỉnh',signed(t.normalizedAmount),true))}`;
    const allocation=valid?`${heading('Kết quả phân bổ',`${preview.length} sản phẩm`)}<section class="v460-allocation-list">${allocationRows13(t)}${ds24KeyValueRow('Tổng phân bổ',signed(total),true)}</section>`:vBanner('warning','Chưa có phương pháp phân bổ hợp lệ','Cần metric hợp lệ và so sánh được trên toàn phạm vi; hệ thống không tự chia đều.');
    const body=`${state==='SOURCE_CHANGED'?vBanner('warning','Nguồn điều chỉnh đã thay đổi','Kiểm tra lại dữ liệu hiện hành trước khi ghi.'):''}${source}${heading('Phạm vi áp dụng','Theo nguồn xác định')}<section class="ds24-list-stack v430-list">${targets}</section>${methodControl13(t)}${allocation}${period13(t)}${confirm13?confirmSheet({title:'Ghi điều chỉnh giá trị?',desc:'Kiểm tra lại tổng tiền, phạm vi, cách phân bổ và kỳ ghi nhận trước khi ghi.',body:flat('Xác nhận',`${ds24InfoRow('Nguồn',t.sourceRef.replace(/ · dòng \d+$/,''))}${ds24InfoRow('Sản phẩm',String(preview.length))}${ds24InfoRow('Cách phân bổ',methodLabel(t))}${ds24InfoRow('Kỳ ghi nhận',[...new Set(preview.map(x=>x.postingPeriod))].join(', ')||'—')}${ds24KeyValueRow('Tổng điều chỉnh',signed(total),true)}`),confirmLabel:'Ghi điều chỉnh',confirmAttr:'data-v461-val13-confirm',closeAttr:'data-v461-val13-confirm-close'}):''}`;
    return appShell({title:'Phân bổ điều chỉnh giá trị',body,actions:primaryFooter('Ghi điều chỉnh','data-v461-val13-open-confirm',!valid)});
  }
  function render089BJ13(state){
    if(activeFlowId!=='UIF-13')return renderGeneric(screens.find(s=>s.id==='SCR-089'),state);const t=val13Current(),res=val13LastResult||val13Result();if(state==='PROCESSING')return appShell({title:'Kết quả điều chỉnh giá trị',body:loadingBody(),centered:true,back:false});if(state==='UNKNOWN'){const attrs=`data-v350-action="handoff-unknown" data-source-flow="UIF-13" data-operation="${escapeAttribute(res.operationId||t.operationId)}" data-scope="${escapeAttribute(t.sourceComponentKey||t.id)}"`;return appShell({title:'Đang xác minh kết quả',body:ioResult('Chưa xác định điều chỉnh đã được ghi hay chưa','Không ghi lại adjustment. Chuyển đúng thao tác này sang xác minh.',[['Nguồn',t.sourceRef],['Trạng thái','Đang xác minh']],'warning'),centered:true,back:false,actions:primaryFooter('Chuyển sang xác minh',attrs)});}if(state==='REJECTED_EXECUTION')return appShell({title:'Kết quả điều chỉnh giá trị',body:ioResult('Chưa ghi điều chỉnh','Không có thay đổi giá trị.',[['Nguồn',t.sourceRef],['Tác động','Không thay đổi']],'warning'),centered:true,back:false,actions:primaryFooter('Xem lại phân bổ','data-v461-val13-back')});
    const allocations=res.allocations||[],periods=[...new Set(allocations.map(x=>x.postingPeriod).filter(Boolean))],detailRows=allocations.map(x=>row({title:x.product,subtitle:`${x.receipt} · ${x.qty} ${x.uom}`,trailing:`<strong class="v460-money-trailing">${signed(x.allocatedAmount)}</strong>`,leading:null,type:'Status',interactive:false})).join('');
    const summary=flat('Kết quả',`${ds24InfoRow('Nguồn',String(res.sourceRef||t.sourceRef).replace(/ · dòng \d+$/,''))}${ds24InfoRow('Sản phẩm bị ảnh hưởng',String(allocations.length))}${ds24InfoRow('Kỳ ghi nhận',periods.join(', ')||'—')}${ds24InfoRow('Giá vốn','Cần cập nhật')}${ds24KeyValueRow('Tổng điều chỉnh',signed(res.normalizedAmount??t.normalizedAmount),true)}`),details=detailRows?`<details class="v430-details v460-details" ${detail13?'open':''}><summary>Xem chi tiết phân bổ (${allocations.length})</summary><div class="v430-details__body"><section class="ds24-list-stack v430-list">${detailRows}</section></div></details>`:'';
    const title=Number(res.normalizedAmount??t.normalizedAmount)<0?'Đã ghi giảm giá trị hàng nhập':'Đã ghi điều chỉnh giá trị hàng nhập';return appShell({title:'Kết quả điều chỉnh giá trị',body:`<div class="io-result">${resultHero(title,'Điều chỉnh đã được ghi; sản phẩm liên quan cần cập nhật giá vốn.')}${summary}${details}</div>`,centered:true,back:false,actions:primaryFooter('Về công việc điều chỉnh','data-v461-val13-list')});
  }

  // ------------------------------------------------------------------
  // BJ14
  // ------------------------------------------------------------------
  const COST_POLICY=window.__VET45_TENANT_COST_POLICY__||{version:'MISSING',method:null,label:'Chưa cấu hình',periodCloseScopes:[]};
  let mode14='RESULT',publish14=false,compare14=false,productDetail14=false;
  window.__VET45_TENANT_COST_POLICY_V461__=COST_POLICY;
  function applyPolicy(r){try{window.__VET45_V399__?.enrichRun?.(r,0);}catch(_){}r.policyMethod=COST_POLICY.method;r.policyLabel=COST_POLICY.label;r.policyVersion=COST_POLICY.version;return r;}
  if(typeof val14Runs!=='undefined')val14Runs.forEach(applyPolicy);
  const baseCreate14=val14CreateRun;
  val14CreateRun=function(){const r=baseCreate14();applyPolicy(r);return r;};
  const scopeLabel14=r=>r.scopeOrigin==='DIRTY_SCOPE'?`${r.productCount||3} sản phẩm cần cập nhật`:r.scope;
  const methodResult=r=>r.policyMethod==='MOVING'?(r.moving||{}):(r.periodic||{});
  const compareResult=r=>r.policyMethod==='MOVING'?(r.periodic||{}):(r.moving||{});
  const compareLabel=r=>r.policyMethod==='MOVING'?'Bình quân cuối kỳ':'Bình quân liên hoàn';
  const policy14=r=>flat('Phương pháp',`${ds24InfoRow('Phương pháp áp dụng',r.policyLabel)}${ds24InfoRow('Chính sách','Theo chính sách của tổ chức')}`,'v460-policy');
  function setup14(r){
    const dirty=mode14==='DIRTY_SETUP',period=dirty?(r.postingPeriod||r.period):val14SetupPeriod;
    if(dirty)return `${flat('Phạm vi cần cập nhật',`${ds24InfoRow('Kỳ ghi nhận',period)}${ds24InfoRow('Phạm vi',scopeLabel14(r))}`)}${policy14(r)}`;
    const periodField=selectField('Kỳ','data-v461-val14-period',`<option ${val14SetupPeriod==='08/2026'?'selected':''}>08/2026</option><option ${val14SetupPeriod==='09/2026'?'selected':''}>09/2026</option>`), opts=COST_POLICY.periodCloseScopes||[];
    if(opts.length===1)val14SetupScope=opts[0].label;
    const scopeOpts=[`<option value="" ${!val14SetupScope?'selected':''} disabled>Chọn phạm vi</option>`,...opts.map(x=>`<option value="${escapeAttribute(x.id)}" ${val14SetupScope===x.label?'selected':''}>${esc(x.label)}</option>`)].join('');
    const scope=opts.length===1?flat('Phạm vi',ds24InfoRow('Phạm vi',opts[0].label)):selectField('Phạm vi','data-v461-val14-scope',scopeOpts);
    return `${periodField}${scope}${policy14(r)}`;
  }
  function results14(r){const x=methodResult(r);return `${ds24SummaryCard('Kết quả sau tính',`${r.policyLabel} · ${scopeLabel14(r)}`,'data-ds-prop-tone="Neutral"')}${keys(`${ds24KeyValueRow('Giá trị tồn cuối',val14Money(x.inventory||0),true)}${ds24KeyValueRow('Giá vốn xuất',val14Money(x.cogs||0),true)}`,'v460-cost-total')}${heading('Thay đổi sẽ ghi khi công bố')}<p class="v460-helper">Chỉ phần chênh lệch dưới đây được ghi; chứng từ lịch sử không bị sửa.</p>${keys(`${ds24KeyValueRow('Điều chỉnh giá vốn xuất',signed(r.cogsTrueUp||0),true)}${ds24KeyValueRow('Điều chỉnh giá trị tồn',signed(r.endingAdjustment||0),true)}`,'v460-cost-delta')}`;}
  function comparison14(r){const x=compareResult(r);return `<details class="v430-details v460-details" ${compare14?'open':''} data-v461-compare><summary>Xem đối chiếu theo ${esc(compareLabel(r))}</summary><div class="v430-details__body">${flat(`${compareLabel(r)} · chỉ đối chiếu`,`${ds24KeyValueRow('Giá trị tồn cuối',val14Money(x.inventory||0))}${ds24KeyValueRow('Giá vốn xuất',val14Money(x.cogs||0))}`)}</div></details>`;}
  function products14(r){const all=r.productResults||[],rows=all.map(x=>row({title:x.product||x.name||'Sản phẩm',subtitle:x.state==='NO_NEW_COST_BASIS'?'Chưa có căn cứ giá vốn mới':`Giá vốn mới ${x.newCost!=null?`${money(x.newCost)}/${x.baseUom||'đơn vị cơ sở'}`:'—'}`,trailing:x.state==='NO_NEW_COST_BASIS'?ds24Badge('Không đổi','Neutral'):'',leading:null,type:'Status',interactive:false})).join('');if(!rows)return '';return `${heading('Kết quả theo sản phẩm',`${r.changedProductCount||0} có thay đổi`)}<details class="v430-details v460-details" ${productDetail14?'open':''} data-v461-products><summary>Xem kết quả theo sản phẩm</summary><div class="v430-details__body"><section class="ds24-list-stack v430-list">${rows}</section></div></details>`;}
  function publishSheet14(r){return confirmSheet({title:'Công bố giá vốn?',desc:'Kết quả đã rà soát sẽ có hiệu lực. Hệ thống chỉ ghi phần chênh lệch, không sửa chứng từ lịch sử.',body:`${flat('Phạm vi công bố',`${ds24InfoRow('Kỳ ghi nhận',r.postingPeriod||r.period)}${ds24InfoRow('Phạm vi',scopeLabel14(r))}${ds24InfoRow('Phương pháp',r.policyLabel)}`)}${keys(`${ds24KeyValueRow('Điều chỉnh giá vốn xuất',signed(r.cogsTrueUp||0),true)}${ds24KeyValueRow('Điều chỉnh giá trị tồn',signed(r.endingAdjustment||0),true)}`)}`,confirmLabel:'Công bố giá vốn',confirmAttr:'data-v461-val14-publish',closeAttr:'data-v461-val14-publish-close'});}
  function workMeta14(r){applyPolicy(r);if(r.status==='DIRTY')return {title:'Cập nhật giá vốn',subtitle:`${r.productCount||3} sản phẩm · có thay đổi giá trị`,label:'Cần tính lại',tone:'Warning'};if(r.status==='READY_FOR_REVIEW')return {title:`Chốt giá vốn ${r.period}`,subtitle:`Đã tính · ${r.productCount||r.scope} · chờ công bố`,label:'Sẵn sàng',tone:'Success'};if(r.status==='BLOCKED')return {title:`Chốt giá vốn ${r.period}`,subtitle:`${r.blockers?.length||0} vấn đề cần xử lý`,label:'Bị chặn',tone:'Warning'};return {title:r.label,subtitle:scopeLabel14(r),label:'Đang xử lý',tone:'Neutral'};}
  function render072BJ14(state){if(activeFlowId!=='UIF-14')return renderGeneric(screens.find(s=>s.id==='SCR-072'),state);if(state==='LOADING')return appShell({title:'Công việc giá vốn',body:loadingBody(),centered:true,back:false});if(state==='PERMISSION_DENIED')return appShell({title:'Công việc giá vốn',body:deniedBody(),centered:true,back:false});const rows=val14Runs.filter(r=>r.status!=='PUBLISHED').map(r=>{const m=workMeta14(r);return row({title:m.title,subtitle:m.subtitle,trailing:ds24Badge(m.label,m.tone),leading:null,type:'Navigation',attrs:`data-v461-val14-run="${r.id}"`});}).join('');return appShell({title:'Công việc giá vốn',body:rows?`<section class="ds24-list-stack v430-list">${rows}</section>`:ioEmpty('Không có công việc giá vốn','Chưa có phạm vi cần cập nhật hoặc chốt kỳ.'),back:false,actions:primaryFooter('Chốt kỳ','data-v461-val14-close-period')});}
  function render074BJ14(state){if(activeFlowId!=='UIF-14')return renderGeneric(screens.find(s=>s.id==='SCR-074'),state);const r=applyPolicy(val14Current());if(state==='PERMISSION_DENIED')return appShell({title:'Tính và rà soát giá vốn',body:deniedBody(),centered:true});if(state==='INPUT_CHANGED'||r.status==='INPUT_CHANGED')return appShell({title:'Tính và rà soát giá vốn',body:`${vBanner('warning','Dữ liệu đầu vào đã thay đổi','Kết quả cũ được giữ để truy vết nhưng không còn đủ điều kiện công bố.')}${policy14(r)}`,actions:primaryFooter('Tạo lần tính kế tiếp','data-v461-val14-successor')});if(mode14==='DIRTY_SETUP'||mode14==='PERIOD_CLOSE_SETUP'){const noScope=mode14==='PERIOD_CLOSE_SETUP'&&(COST_POLICY.periodCloseScopes||[]).length>1&&!val14SetupScope;return appShell({title:mode14==='DIRTY_SETUP'?'Cập nhật giá vốn':'Chốt giá vốn kỳ',body:setup14(r),actions:primaryFooter(mode14==='DIRTY_SETUP'?'Tính lại giá vốn':'Tính giá vốn','data-v461-val14-calculate',noScope)});}if(r.status==='CALCULATING'||state==='PROCESSING')return appShell({title:'Tính và rà soát giá vốn',body:ioResult('Đang tính giá vốn','Có thể rời màn hình. Kết quả được lưu trong cùng lần tính.',[['Kỳ ghi nhận',r.postingPeriod||r.period],['Phạm vi',scopeLabel14(r)]],'info'),centered:true});if(r.status==='BLOCKED'||state==='BLOCKED'){const blockers=(r.blockers||[]).map(b=>context(b.title,`Đang chờ: ${b.owner}`,'Cần xử lý','Warning')).join('');return appShell({title:'Tính và rà soát giá vốn',body:`${vBanner('warning','Chưa thể chốt giá vốn','Xử lý các vấn đề dưới đây trước khi công bố.')}${policy14(r)}${heading('Cần xử lý',`${r.blockers?.length||0} vấn đề`)}<section class="ds24-list-stack v430-list">${blockers}</section>`});}const body=`${policy14(r)}${results14(r)}${comparison14(r)}${products14(r)}${publish14?publishSheet14(r):''}`;return appShell({title:'Tính và rà soát giá vốn',body,actions:primaryFooter('Công bố giá vốn','data-v461-val14-open-publish',r.status!=='READY_FOR_REVIEW')});}
  function render077BJ14(state){if(activeFlowId!=='UIF-14')return renderGeneric(screens.find(s=>s.id==='SCR-077'),state);const r=applyPolicy(val14Current()),res=val14LastResult||{runId:r.id,postingPeriod:r.postingPeriod||r.period,method:r.policyLabel,effectiveAt:r.effectiveAt,cogsTrueUp:r.cogsTrueUp,endingAdjustment:r.endingAdjustment,reconciledProducts:r.productCount||0,officialCostVersions:(r.productResults||[]).filter(x=>x.state!=='NO_NEW_COST_BASIS'&&x.newCost!==x.oldCost).length};if(state==='PROCESSING')return appShell({title:'Kết quả công bố giá vốn',body:loadingBody(),centered:true,back:false});if(state==='UNKNOWN'){const attrs=`data-v350-action="handoff-unknown" data-source-flow="UIF-14" data-operation="${escapeAttribute(res.runId||r.id)}" data-scope="${escapeAttribute(res.postingPeriod||r.period)}"`;return appShell({title:'Đang xác minh kết quả',body:ioResult('Chưa xác định giá vốn đã được công bố hay chưa','Không gửi lại lệnh công bố. Chuyển đúng lần này sang xác minh kết quả.',[['Lần tính',res.runId||r.id],['Trạng thái','Đang xác minh']],'warning'),centered:true,back:false,actions:primaryFooter('Chuyển sang xác minh',attrs)});}if(state==='REJECTED_EXECUTION')return appShell({title:'Kết quả công bố giá vốn',body:ioResult('Chưa công bố giá vốn','Không có điều chỉnh hoặc phiên bản giá vốn mới.',[['Kỳ ghi nhận',res.postingPeriod||r.period],['Tác động','Không thay đổi']],'warning'),centered:true,back:false,actions:primaryFooter('Về công việc giá vốn','data-v461-val14-list')});const body=`<div class="io-result">${resultHero('Đã công bố giá vốn','Phần chênh lệch đã được ghi và giá vốn chính thức mới đã có hiệu lực.')}${flat('Kết quả',`${ds24InfoRow('Kỳ ghi nhận',res.postingPeriod||r.period)}${ds24InfoRow('Phương pháp',res.method||r.policyLabel)}${ds24InfoRow('Sản phẩm đã đối soát',String(res.reconciledProducts||r.productCount||0))}${ds24InfoRow('Sản phẩm có giá vốn mới',String(res.officialCostVersions??0))}${ds24InfoRow('Hiệu lực',res.effectiveAt||r.effectiveAt||'—')}${ds24KeyValueRow('Điều chỉnh giá vốn xuất',signed(res.cogsTrueUp||0),true)}${ds24KeyValueRow('Điều chỉnh giá trị tồn',signed(res.endingAdjustment||0),true)}`)}</div>`;return appShell({title:'Kết quả công bố giá vốn',body,centered:true,back:false,actions:primaryFooter('Về công việc giá vốn','data-v461-val14-list')});}

  // Retire SCR-088 at runtime and preserve legacy deep links.

  // Unique v4.6 interaction attributes prevent legacy event handlers from firing.
  window.addEventListener('change',event=>{
    if(activeFlowId==='UIF-03'&&event.target.matches('[data-v461-basis-currency]')){event.stopImmediatePropagation();ensureBasisDraft().currency=event.target.value;return renderAppScreen();}
    if(activeFlowId==='UIF-14'&&event.target.matches('[data-v461-val14-period]')){event.stopImmediatePropagation();val14SetupPeriod=event.target.value;return renderAppScreen();}
    if(activeFlowId==='UIF-14'&&event.target.matches('[data-v461-val14-scope]')){event.stopImmediatePropagation();const opt=(COST_POLICY.periodCloseScopes||[]).find(x=>x.id===event.target.value);val14SetupScope=opt?.label||'';return renderAppScreen();}
  },true);
  window.addEventListener('input',event=>{
    if(activeFlowId==='UIF-03'&&basisSheetGroup&&event.target.closest('.v430-form-sheet')){
      const root=document.querySelector('.v430-form-sheet');if(root)syncBasisDraft(root);
    }
  },true);
  window.addEventListener('click',event=>{
    let el;
    if(activeFlowId==='UIF-03'){
      if((el=event.target.closest('[data-v461-val03-select]'))){event.preventDefault();event.stopImmediatePropagation();const g=(val03Current().groups||[]).find(x=>x.id===el.dataset.v461Val03Select);if(g&&groupState(val03Current(),g)==='READY')selectGroup(g,!selectedGroups().includes(g));return renderAppScreen();}
      if((el=event.target.closest('[data-v461-val03-add-basis]'))){event.preventDefault();event.stopImmediatePropagation();basisSheetGroup=el.dataset.v461Val03AddBasis;basisDraft={price:'',currency:'',taxMode:'',tax:'',source:'',date:'',ref:'',reason:''};return renderAppScreen();}
      if((el=event.target.closest('[data-v461-tax-mode]'))){event.preventDefault();event.stopImmediatePropagation();ensureBasisDraft().taxMode=el.dataset.v461TaxMode;return renderAppScreen();}
      if((el=event.target.closest('[data-v461-val03-sheet]'))){event.preventDefault();event.stopImmediatePropagation();if(el.dataset.v461Val03Sheet==='close'){basisSheetGroup=null;basisDraft=null;return renderAppScreen();}if(el.dataset.v461Val03Sheet==='save'&&saveBasis(basisSheetGroup)){basisSheetGroup=null;basisDraft=null;return renderAppScreen();}return;}
      if((el=event.target.closest('[data-v461-val03-review]'))){event.preventDefault();event.stopImmediatePropagation();if(!canReview03())return;val03ReviewSourceVersion=val03Current().sourceVersion;stateByScreen['SCR-017']='READY';return navigate('SCR-017');}
      if((el=event.target.closest('[data-v461-val03-back]'))){event.preventDefault();event.stopImmediatePropagation();stateByScreen['SCR-015']='READY';return navigate('SCR-015');}
      if((el=event.target.closest('[data-v461-val03-confirm]'))){event.preventDefault();event.stopImmediatePropagation();if(Number(val03ReviewSourceVersion)!==Number(val03Current().sourceVersion)){stateByScreen['SCR-017']='SOURCE_CHANGED';return renderAppScreen();}val03Commit();stateByScreen['SCR-019']='COMPLETED';return navigate('SCR-019');}
      if((el=event.target.closest('[data-v461-val03-result-list]'))){event.preventDefault();event.stopImmediatePropagation();return navigate('SCR-014');}
    }
    if(activeFlowId==='UIF-13'){
      if((el=event.target.closest('[data-v461-val13-method]'))){event.preventDefault();event.stopImmediatePropagation();const t=val13Current(),id=el.dataset.v461Val13Method;if(eligibleMethods(t).some(m=>m.id===id)){t.selectedMethod=id;val13PreviewHash=null;}return renderAppScreen();}
      if((el=event.target.closest('[data-v461-val13-open-confirm]'))){event.preventDefault();event.stopImmediatePropagation();const t=val13Current();if(!val13CanPreview(t))return;val13ReviewSourceVersion=t.sourceVersion;val13PreviewHash=val13PreviewHashOf(t);confirm13=true;return renderAppScreen();}
      if((el=event.target.closest('[data-v461-val13-confirm-close]'))){event.preventDefault();event.stopImmediatePropagation();confirm13=false;return renderAppScreen();}
      if((el=event.target.closest('[data-v461-val13-confirm]'))){event.preventDefault();event.stopImmediatePropagation();const t=val13Current();if(Number(val13ReviewSourceVersion)!==Number(t.sourceVersion)||val13PreviewHash!==val13PreviewHashOf(t)){confirm13=false;stateByScreen['SCR-086']='SOURCE_CHANGED';return renderAppScreen();}val13Commit();confirm13=false;stateByScreen['SCR-089']='COMPLETED';return navigate('SCR-089');}
      if((el=event.target.closest('[data-v461-val13-back]'))){event.preventDefault();event.stopImmediatePropagation();confirm13=false;stateByScreen['SCR-086']='READY';return navigate('SCR-086');}
      if((el=event.target.closest('[data-v461-val13-list]'))){event.preventDefault();event.stopImmediatePropagation();confirm13=false;return navigate('SCR-085');}
    }
    if(activeFlowId==='UIF-14'){
      if((el=event.target.closest('[data-v461-val14-run]'))){event.preventDefault();event.stopImmediatePropagation();val14SelectedRunId=el.dataset.v461Val14Run;const r=applyPolicy(val14Current());publish14=false;compare14=false;productDetail14=false;if(r.status==='DIRTY'){val14SetupKind='AD_HOC';val14SetupPeriod=r.period;val14SetupScope='Sản phẩm cần tính lại';val14SuccessorOf=r.id;mode14='DIRTY_SETUP';}else{mode14='RESULT';stateByScreen['SCR-074']=r.status==='BLOCKED'?'BLOCKED':'READY';}return navigate('SCR-074');}
      if((el=event.target.closest('[data-v461-val14-close-period]'))){event.preventDefault();event.stopImmediatePropagation();val14SuccessorOf=null;val14SetupKind='PERIOD_CLOSE';val14SetupScope=(COST_POLICY.periodCloseScopes||[]).length===1?COST_POLICY.periodCloseScopes[0].label:'';mode14='PERIOD_CLOSE_SETUP';return navigate('SCR-074');}
      if((el=event.target.closest('[data-v461-val14-calculate]'))){event.preventDefault();event.stopImmediatePropagation();if(mode14==='PERIOD_CLOSE_SETUP'&&(COST_POLICY.periodCloseScopes||[]).length>1&&!val14SetupScope)return;val14SetupKind=mode14==='DIRTY_SETUP'?'AD_HOC':'PERIOD_CLOSE';const run=val14CreateRun();applyPolicy(run);mode14='RESULT';stateByScreen['SCR-074']='READY';return renderAppScreen();}
      if((el=event.target.closest('[data-v461-compare] summary'))){compare14=!compare14;return;}
      if((el=event.target.closest('[data-v461-products] summary'))){productDetail14=!productDetail14;return;}
      if((el=event.target.closest('[data-v461-val14-open-publish]'))){event.preventDefault();event.stopImmediatePropagation();const r=applyPolicy(val14Current());if(r.status!=='READY_FOR_REVIEW')return;val14PublishReviewVersion=r.runInputHash||String(r.inputVersion);publish14=true;return renderAppScreen();}
      if((el=event.target.closest('[data-v461-val14-publish-close]'))){event.preventDefault();event.stopImmediatePropagation();publish14=false;return renderAppScreen();}
      if((el=event.target.closest('[data-v461-val14-publish]'))){event.preventDefault();event.stopImmediatePropagation();const r=applyPolicy(val14Current());if(String(val14PublishReviewVersion)!==String(r.runInputHash||r.inputVersion)){r.status='INPUT_CHANGED';publish14=false;stateByScreen['SCR-074']='INPUT_CHANGED';return renderAppScreen();}val14Commit();publish14=false;stateByScreen['SCR-077']='COMPLETED';return navigate('SCR-077');}
      if((el=event.target.closest('[data-v461-val14-successor]'))){event.preventDefault();event.stopImmediatePropagation();const r=applyPolicy(val14Current());val14SuccessorOf=r.id;val14SetupKind=r.kind;val14SetupPeriod=r.period;val14SetupScope=r.scopeOrigin==='DIRTY_SCOPE'?scopeLabel14(r):((COST_POLICY.periodCloseScopes||[]).some(x=>x.label===r.scope)?r.scope:((COST_POLICY.periodCloseScopes||[]).length===1?COST_POLICY.periodCloseScopes[0].label:''));mode14=r.scopeOrigin==='DIRTY_SCOPE'?'DIRTY_SETUP':'PERIOD_CLOSE_SETUP';return renderAppScreen();}
      if((el=event.target.closest('[data-v461-val14-list]'))){event.preventDefault();event.stopImmediatePropagation();mode14='RESULT';publish14=false;return navigate('SCR-072');}
    }
  },true);

  Object.assign(renderers, {
    'SCR-015': render015BJ03,
    'SCR-017': render017BJ03,
    'SCR-019': render019BJ03,
    'SCR-086': render086BJ13,
    'SCR-087': render086BJ13,
    'SCR-088': function(state){ activeScreenId='SCR-086'; return render086BJ13(state); },
    'SCR-089': render089BJ13,
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

ownedFlows.add("UIF-14");

