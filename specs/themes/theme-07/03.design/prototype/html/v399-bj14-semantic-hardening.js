/* v3.9.9 BJ14 costing-run semantic hardening — D14-01..D14-07 */
(function(){
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
  render072IV14=function(state){
    if(activeFlowId!=="UIF-14")return renderGeneric(screens.find(s=>s.id==="SCR-072"),state); if(state==="PERMISSION_DENIED")return appShell({title:"Giá vốn",body:deniedBody(),centered:true,back:false});
    const active=val14Runs.filter(r=>r.status!=="PUBLISHED");
    const rows=active.map(r=>{enrich(r,0);const [label,tone]=val14StatusMeta(r);const subtitle=r.scopeOrigin==="DIRTY_SCOPE"?`${r.productCount} sản phẩm · ${r.dirtyCauseCount} nguyên nhân cần đối soát`:`${r.scope} · ${r.policyLabel}`;return ds24ListRow({title:r.label,subtitle,trailing:ds24Badge(label,valuationDsTone(tone)),leading:null,attrs:`data-val14-run="${r.id}"`,type:"Navigation"});}).join('');
    return appShell({title:"Giá vốn",body:rows?`<section class="ds24-list-stack valuation-work-list" data-composed-from="DS v2 / List Row,VBadge">${rows}</section>`:ioEmpty("Chưa có lần tính giá vốn","Tạo một lần tính để bắt đầu."),back:false,actions:primaryFooter("Tạo lần tính",'data-val14-action="new-run"')});
  };
  render073IV14=function(state){
    if(activeFlowId!=="UIF-14")return renderGeneric(screens.find(s=>s.id==="SCR-073"),state);if(state==="PERMISSION_DENIED")return appShell({title:"Thiết lập lần tính",body:deniedBody(),centered:true});
    const base=val14SuccessorOf?val14Runs.find(x=>x.id===val14SuccessorOf):null; const dirty=val14SetupKind==="AD_HOC"||base?.scopeOrigin==="DIRTY_SCOPE"; const periodClose=!dirty;
    const setupFacts=ds24InfoGroup("Chính sách áp dụng",`${ds24InfoRow("Thời điểm chốt",periodClose?`Cuối kỳ ${val14SetupPeriod}`:nowLabel)}${ds24InfoRow("Phương pháp công bố",base?.policyLabel||"Bình quân cuối kỳ")}${ds24InfoRow("Kỳ tính",val14SetupPeriod)}${ds24InfoRow("Kỳ ghi nhận",val14SetupPeriod)}`,'valuation-info-group');
    const periodField=`<label class="val14-field valuation-field" data-ds-component="VField"><span>Kỳ</span><select data-val14-period data-ds-component="VSelect" data-figma-node="522:7291"><option ${val14SetupPeriod==="08/2026"?'selected':''}>08/2026</option><option ${val14SetupPeriod==="09/2026"?'selected':''}>09/2026</option></select></label>`;
    const scope=dirty?ds24InfoGroup("Phạm vi cần tính lại",`${ds24InfoRow("Nguồn phạm vi","Điều chỉnh định giá đã ghi")}${ds24InfoRow("Sản phẩm",String(base?.productCount||3))}${ds24InfoRow("Nguyên nhân cần đối soát",String(base?.dirtyCauseCount||3))}`,'valuation-info-group v399-locked-scope'):`<label class="val14-field valuation-field" data-ds-component="VField"><span>Phạm vi</span><select data-val14-scope data-ds-component="VSelect" data-figma-node="522:7291"><option ${val14SetupScope==="Toàn bộ sản phẩm"?'selected':''}>Toàn bộ sản phẩm</option><option ${val14SetupScope==="Sản phẩm cần tính lại"?'selected':''}>Sản phẩm cần tính lại</option></select></label>`;
    const body=`${val14SuccessorOf?vBanner("warning","Dữ liệu đã thay đổi","Lần tính mới dùng phạm vi hiện hành; lần cũ được giữ để truy vết."):""}${ds24SectionTitle("Loại lần tính")}${val14KindChoices()}${periodField}${scope}${setupFacts}`;
    return appShell({title:"Thiết lập lần tính",body,actions:primaryFooter("Tính giá vốn",'data-val14-action="calculate"')});
  };
  render074IV14=function(state){
    if(activeFlowId!=="UIF-14")return renderGeneric(screens.find(s=>s.id==="SCR-074"),state);const r=val14Current();enrich(r,0);if(state==="PERMISSION_DENIED")return appShell({title:"Kết quả lần tính",body:deniedBody(),centered:true});
    if(state==="INPUT_CHANGED")return appShell({title:"Kết quả lần tính",body:`${vBanner("warning","Dữ liệu đầu vào đã thay đổi","Không thể công bố kết quả cũ. Tạo lần tính kế tiếp từ dữ liệu hiện hành.")}${val14RunSummary(r)}`,actions:primaryFooter("Tạo lần tính kế tiếp",'data-val14-action="successor"')});
    if(r.status==="CALCULATING"||state==="PROCESSING")return appShell({title:"Kết quả lần tính",body:ioResult("Đang tính giá vốn","Có thể rời màn hình; kết quả được lưu trong cùng lần tính.",[["Kỳ ghi nhận",r.postingPeriod],["Phạm vi",scopeLabel(r)]],"info"),centered:true});
    if(r.status==="BLOCKED"||state==="BLOCKED")return appShell({title:"Kết quả lần tính",body:`${vBanner("warning","Chưa thể công bố","Xử lý các vấn đề dưới đây trước khi tạo lần tính kế tiếp.")}${val14RunSummary(r)}${ds24SectionTitle("Đang bị chặn",`${r.blockers.length} vấn đề`)}${val14Blockers(r)}`});
    const body=`${val14RunSummary(r)}${v399PeriodFacts(r)}${ds24SectionTitle("Đối chiếu hai phương pháp")}${val14MethodCard(r)}${val14AdjustmentCard(r)}${ds24SectionTitle("Kết quả theo sản phẩm",`${r.changedProductCount} có thay đổi`)}${productRows(r)}`;
    return appShell({title:"Kết quả lần tính",body,actions:primaryFooter("Rà soát công bố",'data-val14-action="review-publish"',r.status!=="READY_FOR_REVIEW")});
  };
  render076IV14=function(state){
    if(activeFlowId!=="UIF-14")return renderGeneric(screens.find(s=>s.id==="SCR-076"),state);const r=val14Current();enrich(r,0);if(state==="PERMISSION_DENIED")return appShell({title:"Rà soát công bố",body:deniedBody(),centered:true});
    const stale=state==="SOURCE_CHANGED"||val14PublishReviewVersion==null||String(val14PublishReviewVersion)!==String(r.runInputHash);
    if(stale)return appShell({title:"Rà soát công bố",body:`${vBanner("warning","Dữ liệu đầu vào đã thay đổi","Không thể công bố lần tính cũ. Tạo một lần tính kế tiếp từ dữ liệu hiện hành.")}${val14RunSummary(r)}`,actions:primaryFooter("Tạo lần tính kế tiếp",'data-val14-action="successor"')});
    const after=ds24InfoGroup("Sau công bố",`${ds24InfoRow("Sản phẩm đối soát",String(r.productCount))}${ds24InfoRow("Phiên bản giá vốn mới",String((r.productResults||[]).filter(x=>x.state!=="NO_NEW_COST_BASIS"&&x.newCost!==x.oldCost).length))}${ds24InfoRow("Hiệu lực","Không sớm hơn thời điểm công bố")}${r.scopeOrigin==="DIRTY_SCOPE"?ds24InfoRow("Phạm vi cần tính lại","Chỉ xóa sau khi ghi thành công"):''}`,'valuation-info-group');
    const body=`${val14RunSummary(r)}${v399PeriodFacts(r)}${val14AdjustmentCard(r,"Chênh lệch sẽ ghi")}${after}`;
    return appShell({title:"Rà soát công bố",body,actions:primaryFooter("Công bố giá vốn",'data-val14-action="publish"',r.status!=="READY_FOR_REVIEW")});
  };
  render077IV14=function(state){
    if(activeFlowId!=="UIF-14")return renderGeneric(screens.find(s=>s.id==="SCR-077"),state);const r=val14Current();const res=val14LastResult||{runId:r.id,period:r.period,postingPeriod:r.postingPeriod||r.period,scope:scopeLabel(r),method:r.policyLabel,effectiveAt:r.effectiveAt,cogsTrueUp:r.cogsTrueUp,endingAdjustment:r.endingAdjustment,reconciledProducts:r.productCount||0,changedProducts:r.changedProductCount||0,officialCostVersions:0,dirtyCausesCleared:0};
    if(state==="PROCESSING")return appShell({title:"Kết quả công bố",body:loadingBody(),centered:true,back:false});
    if(state==="UNKNOWN"){const attrs=`data-v350-action="handoff-unknown" data-source-flow="UIF-14" data-operation="${escapeAttribute(res.runId||r.id)}" data-scope="${escapeAttribute((res.postingPeriod||r.postingPeriod||r.period)+' · '+scopeLabel(r))}"`;return appShell({title:"Đang xác minh kết quả",body:ioResult("Chưa xác định giá vốn đã được công bố hay chưa","Không gửi lại lệnh công bố. Chuyển đúng lần công bố này sang xác minh kết quả.",[["Lần tính",res.runId],["Trạng thái","Đang xác minh"]],"warning"),centered:true,back:false,actions:primaryFooter("Chuyển sang xác minh",attrs)});}
    if(state==="REJECTED_EXECUTION")return appShell({title:"Kết quả công bố",body:ioResult("Chưa công bố giá vốn","Không có điều chỉnh hoặc phiên bản giá vốn mới.",[["Kỳ ghi nhận",res.postingPeriod],["Tác động","Không thay đổi"]],"warning"),centered:true,back:false,actions:primaryFooter("Về kết quả lần tính",'data-val14-action="result-to-run"')});
    if(state==="PERMISSION_DENIED")return appShell({title:"Kết quả công bố",body:deniedBody(),centered:true,back:false,actions:primaryFooter("Về giá vốn",'data-val14-action="result-to-list"')});
    const overview=ds24InfoGroup("Kết quả",`${ds24InfoRow("Lần tính",res.runId)}${ds24InfoRow("Kỳ ghi nhận",res.postingPeriod)}${ds24InfoRow("Phương pháp",res.method)}${ds24InfoRow("Sản phẩm đã đối soát",String(res.reconciledProducts))}${ds24InfoRow("Phiên bản giá vốn mới",String(res.officialCostVersions))}${ds24InfoRow("Hiệu lực",res.effectiveAt)}${ds24KeyValueRow("Giá vốn xuất",val14Money(res.cogsTrueUp),true)}${ds24KeyValueRow("Giá trị tồn cuối",val14Money(res.endingAdjustment),true)}${res.dirtyCausesCleared?ds24InfoRow("Nguyên nhân đã xử lý",String(res.dirtyCausesCleared)):''}`,'valuation-info-group valuation-info-group--wrap');
    return appShell({title:"Kết quả công bố",body:`<div class="io-result val14-result">${resultHero("Đã công bố giá vốn","Chênh lệch và phiên bản giá vốn đã được ghi từ kết quả đã chốt của lần tính.")}${overview}</div>`,centered:true,back:false,actions:primaryFooter("Về giá vốn",'data-val14-action="result-to-list"')});
  };
  // renderers map captured original function references in app.js; rebind BJ14 entries after overrides.
  renderers["SCR-072"]=render072IV14;
  renderers["SCR-073"]=render073IV14;
  renderers["SCR-074"]=render074IV14;
  renderers["SCR-076"]=render076IV14;
  renderers["SCR-077"]=render077IV14;
  window.__VET45_V399__={version:"3.9.9",decisions:[164,165,166,167,168,169,170],enrichRun:enrich};
})();
