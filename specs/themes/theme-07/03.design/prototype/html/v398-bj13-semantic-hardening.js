/* VET45 Theme 7 v3.9.8 — BJ13 late-landed-cost semantic hardening
 * Parent: v3.9.7
 * Approved decisions: T7-DR-157..163 / D13-01..D13-07
 */
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
    const value=quantityMethod?Math.max(0,Number(x.baseQty)||0):Math.max(0,Number(x.initialDirectValue)||0);
    const unit=quantityMethod?'base_quantity':'initial_direct_value_vnd';
    const version=quantityMethod?'METRIC-QTY-v1':'METRIC-INITIAL-VALUE-v1';
    return {method,metricValue:value,unit,metricVersion:version,metricHash:stableHash({exposure:x.valuationExposureKey,method,value,unit,version})};
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
    let weightTotal=metrics.reduce((n,m)=>n+m.metricValue,0); if(weightTotal<=0) weightTotal=selected.length;
    const amounts=new Map(); let used=0;
    selected.forEach((x,i)=>{
      const weight=metrics[i].metricValue>0?metrics[i].metricValue:(weightTotal===selected.length?1:0);
      const amount=i===selected.length-1?total-used:Math.round(total*(weight/weightTotal));
      used+=amount; amounts.set(x.valuationExposureKey,{amount,metric:metrics[i]});
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
  function canPreview(t=val13Current()){return canOpen(t)&&t.allowedMethods.some(m=>m.id===t.selectedMethod);}

  val13SelectedTargets=selectedTargets;
  val13AllocationWeight=(target,method)=>metricSnapshot(val13Current(),target,method).metricValue;
  val13Preview=allocate;
  val13PreviewHashOf=combinedPreviewHash;
  val13CanOpenAllocation=canOpen;
  val13CanPreview=canPreview;
  val13DirtyScope=(t=val13Current())=>dirtyScopes(t).map(x=>x.label);
  val13StatusMeta=function(t){if(t.status==='WAITING')return [t.waitingOwner||'Đang chờ','neutral'];return ['', 'neutral'];};
  val13ResetTaskDraft=function(t){for(const x of (t.targets||[]))x.selected=t.targetScopeMode==='FIXED'?true:true;t.selectedMethod=t.allowedMethods?.length===1?t.allowedMethods[0].id:'';val13ReviewSourceVersion=null;val13PreviewHash=null;val13LastSourceChange=null;};
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

  render085IV13=function(state){
    if(activeFlowId!=='UIF-13')return renderGeneric(screens.find(s=>s.id==='SCR-085'),state);
    if(state==='PERMISSION_DENIED')return appShell({title:'Chi phí mua bổ sung',body:deniedBody(),centered:true,back:false});
    if(state==='FINANCIAL_MASKED')return appShell({title:'Chi phí mua bổ sung',body:ioEmpty('Không có quyền xem dữ liệu tài chính','Liên hệ người quản trị nếu bạn cần xử lý chi phí mua.'),centered:true,back:false});
    const all=val13Tasks.filter(t=>t.status!=='COMPLETED');const filtered=all.filter(t=>{const ok=val13Filter==='ALL'||(val13Filter==='ACTIONABLE'&&t.status==='ACTIONABLE')||(val13Filter==='WAITING'&&t.status==='WAITING');return ok&&(!val13Query||val13TaskSearchText(t).includes(ioNormalizeSearch(val13Query)));});
    if(state==='EMPTY'&&!all.length)return appShell({title:'Chi phí mua bổ sung',body:ioEmpty('Không có chi phí mua bổ sung','Các chứng từ cần xử lý sẽ xuất hiện tại đây.'),centered:true,back:false});
    const rows=filtered.map(t=>ds24ListRow({title:val13QueueTitle(t),subtitle:`${t.component} · ${t.supplier}`,trailing:t.status==='WAITING'?ds24Badge('Đang chờ','neutral'):'',leading:null,attrs:`data-val13-task="${t.id}"`,type:'Navigation',state:t.status==='WAITING'?'Disabled':'Default',disabled:t.status==='WAITING'})).join('');
    const body=`${ds24Search(val13Query,'data-val13-search','Chứng từ chi phí hoặc nhà cung cấp')}<div class="ds24-chip-scroll" aria-label="Lọc chi phí mua bổ sung">${[['ALL','Tất cả'],['ACTIONABLE','Có thể xử lý'],['WAITING','Đang chờ']].map(([k,l])=>ds24Chip(k,l,val13Filter===k,'data-val13-filter')).join('')}</div>${filtered.length?`<section class="ds24-list-stack valuation-work-list" data-composed-from="DS v2 / List Row,VBadge">${rows}</section>`:ioEmpty('Không tìm thấy công việc phù hợp','Đổi từ khóa hoặc bộ lọc để xem công việc khác.')}`;
    return appShell({title:'Chi phí mua bổ sung',body,back:false});
  };
  render086IV13=function(state){
    if(activeFlowId!=='UIF-13')return renderGeneric(screens.find(s=>s.id==='SCR-086'),state);const t=val13Current();
    if(state==='LOADING')return appShell({title:'Nguồn và phạm vi chi phí',body:loadingBody(),centered:true});
    if(state==='PERMISSION_DENIED')return appShell({title:'Nguồn và phạm vi chi phí',body:deniedBody(),centered:true});
    if(state==='FINANCIAL_MASKED')return appShell({title:'Nguồn và phạm vi chi phí',body:ioEmpty('Không có quyền xem dữ liệu tài chính','Không thể hiển thị nguồn và phạm vi chi phí.'),centered:true});
    if(t.status==='WAITING')return appShell({title:'Nguồn và phạm vi chi phí',body:`${vBanner('info','Chưa thể xử lý',t.waitingOwner||'Đang chờ căn cứ cần thiết.')}${val13SourceCard(t)}`});
    const changed=state==='SOURCE_CHANGED'||Boolean(val13LastSourceChange),selected=selectedTargets(t).length,scopeText=t.targetScopeMode==='FIXED'?`${t.targets.length} dòng theo chứng từ nguồn`:`${selected}/${t.targets.length} dòng đã chọn`;
    const body=`${changed?vBanner('warning','Nguồn chi phí vừa thay đổi',val13LastSourceChange?`Giá trị chuẩn hóa ${val13LastSourceChange.from} → ${val13LastSourceChange.to}. Kiểm tra lại phạm vi hiện hành trước khi tiếp tục.`:'Tải lại nguồn hiện hành trước khi tiếp tục.') : ''}${val13SourceCard(t)}${ds24SectionTitle('Phạm vi liên quan',scopeText)}${ds24GroupedCollection(val13TargetHtml(t),'valuation-selection-collection val13-target-list','VText')}`;
    return appShell({title:'Nguồn và phạm vi chi phí',body,actions:primaryFooter('Tiếp tục phân bổ','data-val13-action="scope-to-allocation"',!canOpen(t))});
  };
  render087IV13=function(state){
    if(activeFlowId!=='UIF-13')return renderGeneric(screens.find(s=>s.id==='SCR-087'),state);const t=val13Current();
    if(state==='LOADING')return appShell({title:'Phân bổ chi phí',body:loadingBody(),centered:true});
    if(state==='PERMISSION_DENIED')return appShell({title:'Phân bổ chi phí',body:deniedBody(),centered:true});
    if(state==='FINANCIAL_MASKED')return appShell({title:'Phân bổ chi phí',body:ioEmpty('Không có quyền xem dữ liệu tài chính','Không thể hiển thị phân bổ chi phí.'),centered:true});
    if(state==='SOURCE_CHANGED')return appShell({title:'Phân bổ chi phí',body:`${vBanner('warning','Căn cứ phân bổ đã thay đổi','Preview cũ không còn hợp lệ.')}${val13SourceCard(t)}`,actions:primaryFooter('Kiểm tra lại phạm vi','data-val13-action="back-scope"')});
    const preview=allocate(t),total=preview.reduce((n,x)=>n+x.allocatedAmount,0),opts=`<option value="">Chọn căn cứ phân bổ</option>`+t.allowedMethods.map(m=>`<option value="${m.id}" ${m.id===t.selectedMethod?'selected':''}>${esc(m.label)}</option>`).join('');
    const normalized=ds24InfoGroup('Chi phí cần phân bổ',`${ds24InfoRow('Giá trị nguồn',val13FmtSourceAmount(t))}${t.currency!=='VND'?ds24InfoRow('Tỷ giá',t.fxLabel):''}${ds24KeyValueRow('Sau chuẩn hóa',val13FmtMoney(t.normalizedAmount),true)}`,'valuation-info-group');
    const allocationBody=canPreview(t)?`${ds24SectionTitle('Kết quả phân bổ',`${preview.length} dòng`)}${ds24GroupedCollection(`${val13AllocationRows(t)}<div class="valuation-total-strip valuation-total-strip--inside">${ds24KeyValueRow('Tổng phân bổ',val13FmtMoney(total),true)}</div>`,'valuation-allocation-collection val13-allocation-list','VText,DS v2 / Key-value Row')}${val13PeriodCard(t)}`:vBanner('info','Chọn căn cứ phân bổ','Chọn một căn cứ được phép để xem phân bổ trước khi rà soát.','', 'Compact');
    const body=`${normalized}${ds24SectionTitle('Căn cứ phân bổ')}<label class="val13-select-field valuation-field" data-ds-component="VField"><span>Căn cứ phân bổ</span><select data-val13-method data-ds-component="VSelect" data-figma-node="522:7291">${opts}</select></label>${allocationBody}`;
    return appShell({title:'Phân bổ chi phí',body,actions:primaryFooter('Rà soát ghi chi phí','data-val13-action="open-review"',!canPreview(t))});
  };
  render088IV13=function(state){
    if(activeFlowId!=='UIF-13')return renderGeneric(screens.find(s=>s.id==='SCR-088'),state);const t=val13Current();
    if(state==='PERMISSION_DENIED')return appShell({title:'Rà soát ghi chi phí',body:deniedBody(),centered:true});
    if(state==='FINANCIAL_MASKED')return appShell({title:'Rà soát ghi chi phí',body:ioEmpty('Không có quyền xem dữ liệu tài chính','Không thể rà soát hoặc ghi chi phí.'),centered:true});
    const stale=state==='SOURCE_CHANGED'||val13PreviewHash==null||val13PreviewHash!==combinedPreviewHash(t);
    if(stale)return appShell({title:'Rà soát ghi chi phí',body:`${vBanner('warning','Nguồn hoặc phân bổ đã thay đổi','Tạo lại phân bổ trước khi ghi chi phí.')}${val13SourceCard(t)}`,actions:primaryFooter('Tạo lại phân bổ','data-val13-action="back-allocation"')});
    const body=`${val13ReviewBody(t)}<button type="button" class="io-text-action valuation-text-action" data-val13-action="back-allocation" data-ds-component="DS v2 / Link" data-figma-node="4431:10396">Chỉnh sửa phân bổ</button>`;
    return appShell({title:'Rà soát ghi chi phí',body,actions:primaryFooter('Ghi chi phí mua bổ sung','data-val13-action="confirm-late-cost"')});
  };
  render089IV13=function(state){
    if(activeFlowId!=='UIF-13')return renderGeneric(screens.find(s=>s.id==='SCR-089'),state);const res=val13Result();
    if(state==='PROCESSING')return appShell({title:'Kết quả ghi chi phí',body:loadingBody(),centered:true,back:false});
    if(state==='UNKNOWN'){const operation=res.operationId||val13Current().operationId,scope=res.sourceRef||val13Current().sourceRef;const attrs=`data-v350-action="handoff-unknown" data-source-flow="UIF-13" data-operation="${esc(operation)}" data-scope="${esc(scope)}"`;return appShell({title:'Đang xác minh kết quả',body:ioResult('Chưa xác định thao tác đã ghi hay chưa','Không gửi lại chi phí. Giữ nguyên đúng lần xử lý này và chuyển sang xác minh trước mọi lần thử khác.',[['Chứng từ chi phí',scope],['Trạng thái','Đang xác minh']],'warning'),centered:true,back:false,actions:primaryFooter('Chuyển sang xác minh',attrs)});}
    if(state==='REJECTED_EXECUTION')return appShell({title:'Kết quả ghi chi phí',body:ioResult('Chưa ghi chi phí mua bổ sung','Không có thay đổi. Kiểm tra lại nguồn, phạm vi và phân bổ hiện hành.',[['Chứng từ chi phí',res.sourceRef],['Tác động','Không thay đổi']],'warning'),centered:true,back:false,actions:primaryFooter('Xem lại phân bổ','data-val13-action="back-allocation"')});
    if(state==='PERMISSION_DENIED'||state==='FINANCIAL_MASKED')return appShell({title:'Kết quả ghi chi phí',body:deniedBody(),centered:true,back:false,actions:primaryFooter('Về chi phí mua bổ sung','data-val13-action="result-to-queue"')});
    const allocationSummary=(res.allocations||[]).map(x=>`<div class="val13-result-line valuation-allocation-row"><span><strong>${esc(x.product)}</strong><small>${esc(x.receipt)} · ${x.qty} ${esc(x.uom)}${x.lot?` · Lô ${esc(x.lot)}`:''}</small></span><strong class="valuation-amount">${esc(val13FmtMoney(x.allocatedAmount))}</strong></div>`).join('');
    const periodText=(res.periodGroups||[]).map(g=>g.postingPeriod).join(', ')||'—';
    const overview=ds24InfoGroup('Kết quả',`${ds24InfoRow('Chứng từ',res.sourceRef)}${ds24KeyValueRow('Chi phí đã ghi',val13FmtMoney(res.normalizedAmount),true)}${ds24InfoRow('Kỳ ghi nhận',periodText)}${ds24InfoRow('Cần tính lại',(res.dirtyScope||[]).map(x=>x.label||x).join('; ')||'—')}`,'valuation-info-group valuation-info-group--wrap');
    const body=`<div class="io-result val13-result">${resultHero('Đã ghi chi phí mua bổ sung','Chi phí đã được ghi theo đúng phạm vi và kỳ đã xác nhận.')}${overview}${ds24SectionTitle('Phân bổ đã ghi')}${ds24GroupedCollection(allocationSummary,'valuation-allocation-collection val13-result-lines','VText')}</div>`;
    return appShell({title:'Kết quả ghi chi phí',body,centered:true,back:false,actions:primaryFooter('Về chi phí mua bổ sung','data-val13-action="result-to-queue"')});
  };

  if(typeof renderers!=='undefined'){
    renderers['SCR-085']=render085IV13;renderers['SCR-086']=render086IV13;renderers['SCR-087']=render087IV13;renderers['SCR-088']=render088IV13;renderers['SCR-089']=render089IV13;
  }

  window.val13V398={lateCostBasisPayload,lateCostBasisHash,allocationHash,combinedPreviewHash,metricSnapshot,allocate,dirtyScopes,periodGroups,allInitialValued,economicIdentity:(t=val13Current())=>t.sourceComponentKey,touchExposure:(id)=>{const t=val13Current(),x=t.targets.find(y=>y.id===id);if(!x)return false;x.exposureVersion+=1;x.exposureHash=stableHash({key:x.valuationExposureKey,version:x.exposureVersion,qty:x.baseQty,value:x.initialDirectValue,refs:x.receiptValuationRefs,businessDate:x.businessDate,original:x.originalPeriod,posting:x.postingPeriod});return true;},shuffleTargets:(t=val13Current())=>{t.targets.reverse();return true;}};
  if(window.__VET45_PROTOTYPE__) window.__VET45_PROTOTYPE__.version='3.9.8';
})();
