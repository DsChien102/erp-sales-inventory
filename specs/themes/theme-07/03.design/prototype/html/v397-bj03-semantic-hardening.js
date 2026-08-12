/* VET45 Theme 7 v3.9.7 — BJ03 direct valuation semantic hardening
 * Parent: v3.9.6
 * Approved decisions: T7-DR-150..156 / D03-01..D03-07
 */
(()=>{
  if(typeof val03Receipts==='undefined') return;

  const fmt=(n)=>`${Math.round(Number(n)||0).toLocaleString('vi-VN')} đ`;
  const stableHash=(parts)=>`sha256-fixture-${String(parts).replace(/[^a-zA-Z0-9]+/g,'-').toLowerCase()}`;

  function basisCandidate({id,label,version,unitPrice,currency='VND',fxRate=1,fxLabel='VND',unitLineDiscount=0,unitDocDiscount=0,unitKnownCost=0,unitNonDeductibleVat=0,components=[],evidenceRefs=[]}){
    const unitActual=unitPrice*fxRate-unitLineDiscount-unitDocDiscount+unitKnownCost+unitNonDeductibleVat;
    return {id,label,version:`v${version}`,basisVersion:version,basisHash:stableHash(`${id}|${version}|${unitActual}|${currency}|${fxRate}|${components.map(x=>`${x.type}:${x.source}:${x.version}:${x.amount||''}`).join('|')}`),authoritativeValueHash:stableHash(`${currency}|${fxRate}|${unitActual}`),unitPrice,currency,fxRate,fxLabel,unitLineDiscount,unitDocDiscount,unitKnownCost,unitNonDeductibleVat,components,evidenceRefs,provenance:components.map(x=>`${x.label} · ${x.source} ${x.version||''}`.trim())};
  }

  // Recast legacy source fixtures as complete DirectCostBasis candidates.
  for(const [ri,r] of val03Receipts.entries()){
    for(const [gi,g] of r.groups.entries()){
      g.receiptItemRef=g.receiptItemRef||`${r.id}-ITEM-${gi+1}`;
      g.valuationBasisKey=g.valuationBasisKey||`VB-${g.id}`;
      g.baseUom=g.baseUom||g.uom;
      g.conversionToBase=Number(g.conversionToBase||1);
      g.conversionVersion=g.conversionVersion||`CONV-${g.code}-v1`;
      g.basisDisplayLabel=g.basisDisplayLabel||`Dòng nguồn ${gi+1}`;
      for(const s of g.slices){
        s.originalQty=Number(s.originalQty??s.pendingQty);
        s.confirmedQty=Number(s.confirmedQty||0);
        s.confirmedValue=Number(s.confirmedValue||0);
      }
    }
  }
  const g1=val03Receipts[0].groups[0];
  g1.baseUom='lọ'; g1.conversionToBase=10; g1.conversionVersion='CONV-SP00142-v2';
  g1.sources=[basisCandidate({id:'BASIS-G1-A',label:'Căn cứ tổng hợp PO-2608-041',version:4,unitPrice:83000,unitLineDiscount:1000,unitDocDiscount:500,unitKnownCost:200,components:[
    {type:'PURCHASE_PRICE',label:'Giá mua',source:'PO-2608-041',version:'v3',amount:83000},
    {type:'LINE_DISCOUNT',label:'Chiết khấu dòng',source:'PO-2608-041',version:'v3',amount:-1000},
    {type:'DOCUMENT_DISCOUNT',label:'Chiết khấu phiếu đã phân bổ',source:'PO-2608-041',version:'ALLOC-v2',amount:-500},
    {type:'KNOWN_PURCHASE_COST',label:'Chi phí mua đã có',source:'CTCP-2608-12',version:'v1',amount:200},
    {type:'SUPPLIER_CONFIRMATION',label:'Bằng chứng bổ sung',source:'Xác nhận NCC 02/09',version:'v1'}
  ],evidenceRefs:['PO-2608-041 v3','Xác nhận NCC 02/09 v1']})];
  g1.selectedSource='BASIS-G1-A';

  const g2=val03Receipts[0].groups[1];
  g2.sources=[
    basisCandidate({id:'BASIS-G2-PO',label:'Căn cứ theo PO-2608-041',version:3,unitPrice:120000,components:[{type:'PURCHASE_PRICE',label:'Giá mua',source:'PO-2608-041',version:'v3',amount:120000}]}),
    basisCandidate({id:'BASIS-G2-SUP',label:'Căn cứ theo xác nhận NCC 02/09',version:2,unitPrice:121000,components:[{type:'PURCHASE_PRICE',label:'Giá mua',source:'Xác nhận NCC 02/09',version:'v2',amount:121000}]})
  ];
  g2.selectedSource='';

  const g4=val03Receipts[2].groups[0];
  g4.sources=[basisCandidate({id:'BASIS-G4-A',label:'Căn cứ xác nhận NCC 01/09 + tỷ giá kế toán',version:2,unitPrice:4.1,currency:'USD',fxRate:24450,fxLabel:'Tỷ giá kế toán 24.450 VND/USD',components:[{type:'PURCHASE_PRICE',label:'Giá mua',source:'Xác nhận NCC 01/09',version:'v2',amount:4.1},{type:'FX',label:'Tỷ giá',source:'Kế toán',version:'FX-v7',amount:24450}]})];
  g4.selectedSource='BASIS-G4-A';
  const g5=val03Receipts[3].groups[0];
  g5.sources=[basisCandidate({id:'BASIS-G5-A',label:'Căn cứ theo PO-2609-008',version:1,unitPrice:46000,components:[{type:'PURCHASE_PRICE',label:'Giá mua',source:'PO-2609-008',version:'v1',amount:46000}]})];
  g5.selectedSource='BASIS-G5-A';

  let reviewTokens=null;
  function chosenBasis(g){return g.sources.find(x=>x.id===g.selectedSource)||null;}
  function basisState(g){
    if(!g.sources.length) return 'MISSING';
    const valueHashes=new Set(g.sources.map(x=>x.authoritativeValueHash));
    return valueHashes.size>1?'CONFLICT':'READY';
  }
  function ensureSingleBasis(g){if(basisState(g)==='READY'&&g.sources.length&&!g.selectedSource) g.selectedSource=g.sources[0].id;}
  function unitActual(g){const b=chosenBasis(g); if(!b) return null; return b.unitPrice*b.fxRate-(b.unitLineDiscount||0)-(b.unitDocDiscount||0)+(b.unitKnownCost||0)+(b.unitNonDeductibleVat||0);}
  function normalizedBaseCost(g){const u=unitActual(g); return u==null?null:u/Math.max(1,Number(g.conversionToBase)||1);}
  function selectedQty(g){return g.slices.filter(s=>s.selected&&s.pendingQty>0).reduce((n,s)=>n+Math.min(Number(s.selectedQty)||0,s.pendingQty),0);}
  function confirmationAmount(g,s,q){
    const u=unitActual(g); if(u==null||q<=0) return 0;
    const original=Number(s.originalQty||s.pendingQty+s.confirmedQty||q);
    const fullScopeValue=Number(s.scopeAllocatedValue ?? Math.round(u*original));
    const newCumQty=Math.min(original,Number(s.confirmedQty||0)+q);
    const cumulativeTarget=Math.round(fullScopeValue*(newCumQty/original));
    return cumulativeTarget-Number(s.confirmedValue||0);
  }
  function calc(g){
    ensureSingleBasis(g);
    const b=chosenBasis(g),qty=selectedQty(g); if(!b||qty<=0) return null;
    let value=0;
    for(const s of g.slices.filter(x=>x.selected&&x.pendingQty>0)){
      const q=Math.min(Number(s.selectedQty)||0,s.pendingQty); value+=confirmationAmount(g,s,q);
    }
    const actual=unitActual(g),base=normalizedBaseCost(g);
    return {qty,value,unitActual:actual,normalizedBaseCost:base,baseVnd:b.unitPrice*b.fxRate,src:b};
  }
  function currentTokenMap(r=val03Current()){
    const out={};
    for(const g of r.groups.filter(x=>selectedQty(x)>0)){
      ensureSingleBasis(g); const b=chosenBasis(g); if(!b) continue;
      out[g.id]={basisKey:g.valuationBasisKey,basisVersion:b.basisVersion,basisHash:b.basisHash,scopes:g.slices.filter(s=>s.selected&&s.pendingQty>0).map(s=>({id:s.id,scopeVersion:s.scopeVersion}))};
    }
    return out;
  }
  function tokenStale(r=val03Current()){
    if(!reviewTokens) return false;
    const now=currentTokenMap(r);
    for(const [gid,t] of Object.entries(reviewTokens)){
      const n=now[gid]; if(!n||n.basisKey!==t.basisKey||n.basisVersion!==t.basisVersion||n.basisHash!==t.basisHash) return true;
      for(const s of t.scopes){const x=n.scopes.find(a=>a.id===s.id); if(!x||x.scopeVersion!==s.scopeVersion) return true;}
    }
    return false;
  }
  function duplicateBasisMeta(r,g){
    const dup=r.groups.filter(x=>x.code===g.code&&x.uom===g.uom&&x.slices.some(s=>s.pendingQty>0));
    return dup.length>1?`${g.basisDisplayLabel} · ${g.receiptItemRef}`:'';
  }
  function bootstrapConflict(r=val03Current()){
    const byProduct=new Map();
    for(const g of r.groups.filter(x=>selectedQty(x)>0&&x.officialCostStatus==='NONE')){
      const c=calc(g); if(!c) continue; const key=g.code; const arr=byProduct.get(key)||[]; arr.push(Math.round(c.normalizedBaseCost*1e6)/1e6); byProduct.set(key,arr);
    }
    return [...byProduct.values()].some(a=>new Set(a).size>1);
  }

  val03EvidenceState=basisState;
  val03Source=chosenBasis;
  val03GroupSelectedQty=selectedQty;
  val03Calc=calc;
  val03SourceDetail=function(g){const b=chosenBasis(g);return b?b.label:'Chưa chọn';};
  val03ScopeReady=function(r=val03Current()){
    const sel=val03SelectedSlices(r); if(!sel.length||bootstrapConflict(r)) return false;
    return r.groups.every(g=>{
      if(selectedQty(g)<=0) return true; const st=basisState(g); if(st==='MISSING') return false; if(st==='CONFLICT'&&(!g.selectedSource||!g.reason.trim())) return false; return !!chosenBasis(g);
    });
  };
  val03HasSelectedConflict=function(r=val03Current()){return r.groups.some(g=>selectedQty(g)>0&&basisState(g)==='CONFLICT'&&(!g.selectedSource||!g.reason.trim()));};
  val03TotalValue=function(r=val03Current()){return r.groups.reduce((n,g)=>n+(calc(g)?.value||0),0);};
  val03ReceiptState=function(r){const a=val03PendingSlices(r).filter(x=>basisState(x.group)!=='MISSING');if(!a.length)return 'WAITING';return a.some(x=>basisState(x.group)==='CONFLICT')?'CONFLICT':'READY';};
  val03ActionablePairs=function(r=val03Current()){return val03PendingSlices(r).filter(x=>basisState(x.group)!=='MISSING');};
  val03WaitingPairs=function(r=val03Current()){return val03PendingSlices(r).filter(x=>basisState(x.group)==='MISSING');};
  val03SourcePriceText=function(src,uom){return src.currency==='VND'?`${fmt(src.unitPrice)}/${uom}`:`${Number(src.unitPrice).toLocaleString('vi-VN')} ${src.currency}/${uom}`;};

  val03ApplySourceUpdate=function(groupId,newPrice){
    const r=val03Current(),g=r.groups.find(x=>x.id===groupId); if(!g||!g.sources.length)return false;
    const b=g.sources[0],before=val03SourcePriceText(b,g.uom),selectedAffected=activeScreenId==='SCR-017'&&selectedQty(g)>0;
    b.unitPrice=newPrice; b.basisVersion=Number(b.basisVersion||1)+1; b.version=`v${b.basisVersion}`;
    const actual=b.unitPrice*b.fxRate-(b.unitLineDiscount||0)-(b.unitDocDiscount||0)+(b.unitKnownCost||0)+(b.unitNonDeductibleVat||0);
    b.basisHash=stableHash(`${b.id}|${b.basisVersion}|${actual}|${Date.now()}`); b.authoritativeValueHash=stableHash(`${b.currency}|${b.fxRate}|${actual}`);
    val03LastSourceChange={name:g.name,source:b.label,from:before,to:val03SourcePriceText(b,g.uom)};
    if(basisState(g)==='CONFLICT'){g.selectedSource='';g.reason='';}
    // Preserve legacy sourceVersion only as a compatibility trigger when the selected reviewed basis changed.
    if(selectedAffected) r.sourceVersion+=1;
    return true;
  };
  window.val03ApplySourceUpdate=val03ApplySourceUpdate;

  val03Commit=function(){
    const r=val03Current(),selected=val03SelectedSlices(r),groups=[]; let totalValue=0;
    const productBootstrapTaken=new Set();
    for(const g of r.groups.filter(x=>selectedQty(x)>0)){
      const c=calc(g); if(!c) continue;
      const slices=[]; let groupValue=0;
      for(const s of g.slices.filter(x=>x.selected&&x.pendingQty>0)){
        const q=Math.min(Number(s.selectedQty)||0,s.pendingQty),amount=confirmationAmount(g,s,q),ad=val03SelectedAvailability(g,s);
        groupValue+=amount;
        slices.push({scopeKey:s.scopeKey,lot:s.lot,state:s.stateLabel,qty:q,value:amount,availabilityDelta:ad,availabilityNote:s.availabilityNote,businessDate:r.receivedAt});
      }
      let bootstrapStatus='NOT_APPLICABLE';
      if(g.officialCostStatus==='NONE'){
        if(!productBootstrapTaken.has(g.code)){bootstrapStatus='INITIALIZED';productBootstrapTaken.add(g.code);}
        else bootstrapStatus='ALREADY_INITIALIZED';
      }
      groups.push({name:g.name,code:g.code,uom:g.uom,baseUom:g.baseUom,receiptItemRef:g.receiptItemRef,basisKey:g.valuationBasisKey,basisHash:c.src.basisHash,tracking:g.tracking,qty:c.qty,value:groupValue,unitActual:c.unitActual,normalizedBaseCost:c.normalizedBaseCost,source:c.src.label,officialCostBootstrapStatus:bootstrapStatus,slices});
      totalValue+=groupValue;
    }
    val03LastResult={operationId:`VAL-260904-${String(val03OperationSeq++).padStart(3,'0')}`,receipt:r.receipt,supplier:r.supplier,businessDate:r.receivedAt,recordedAt:'16/09/2026 16:25',accountingPeriod:r.receivedAt.slice(3),groups,totalValue};
    for(const {group,slice} of selected){
      const q=Math.min(Number(slice.selectedQty)||0,slice.pendingQty),amount=confirmationAmount(group,slice,q);
      slice.pendingQty-=q; slice.confirmedQty=Number(slice.confirmedQty||0)+q; slice.confirmedValue=Number(slice.confirmedValue||0)+amount; slice.scopeVersion+=1; slice.selected=false; slice.partialOpen=false; slice.selectedQty=slice.pendingQty;
      if(group.officialCostStatus==='NONE') group.officialCostStatus='EXISTS';
    }
    val03ReviewSourceVersion=null; reviewTokens=null; return val03LastResult;
  };

  val03ScopeGroupsHtml=function(r){
    const content=r.groups.filter(g=>g.slices.some(s=>s.pendingQty>0)).map(g=>{
      const st=basisState(g),badge=st==='MISSING'?['Chờ căn cứ','Neutral']:st==='CONFLICT'?['Cần đối chiếu','Warning']:['Đủ căn cứ','Success'];
      const rows=g.slices.filter(s=>s.pendingQty>0).map(s=>{
        const disabled=st==='MISSING',qty=Math.min(Number(s.selectedQty)||0,s.pendingQty),partial=s.selected?`<div class="val03-partial-controls"><button class="val03-partial-link" type="button" data-val03-partial="${s.id}" data-ds-component="DS v2 / Link" data-figma-node="4431:10396">${s.partialOpen?'Dùng toàn bộ':'Xác nhận một phần'}</button>${s.partialOpen?`<label class="val03-qty" data-ds-component="VTextField" data-figma-node="522:7186"><span>Số lượng lần này</span><input type="number" min="1" max="${s.pendingQty}" value="${qty}" data-val03-qty="${s.id}"/><small>Tối đa ${s.pendingQty} ${esc(g.uom)}</small></label>`:''}</div>`:'';
        return `<div class="valuation-child-item val03-scope-item${s.selected?' is-selected':''}${disabled?' is-disabled':''}"><button type="button" class="valuation-child-row val03-check" data-val03-slice="${s.id}" aria-pressed="${s.selected}" ${disabled?'disabled aria-disabled="true"':''} data-composed-from="VCheckbox,VText"><span class="valuation-child-branch" aria-hidden="true"></span><span class="valuation-selection-control val03-check-mark" aria-hidden="true" data-ds-component="VCheckbox" data-ds-prop-state="${disabled?'Disabled':s.selected?'Checked':'Unchecked'}">${s.selected?icon('check','icon--xs'):''}</span><span class="valuation-child-copy"><strong>${esc(val03ScopeLabel(g,s))}</strong><small>${esc(s.stateLabel)} · Chờ giá ${s.pendingQty} ${esc(g.uom)}</small></span></button>${partial}</div>`;
      }).join('');
      return `<div class="valuation-product-group" data-valuation-basis="${escapeAttribute(g.valuationBasisKey)}">${valuationProductHeader({name:g.name,code:g.code,uom:g.uom,status:badge[0],tone:badge[1],meta:duplicateBasisMeta(r,g)})}<div class="valuation-child-list">${rows}</div></div>`;
    }).join('');
    return ds24GroupedCollection(content,'valuation-product-collection val03-product-collection','DS v2 / Icon,VBadge,VCheckbox,VText,VTextField');
  };

  function componentsHtml(b){
    if(!b?.components?.length)return '';
    return `<div class="valuation-provenance" data-composed-from="VText"><strong>Thành phần của căn cứ</strong>${b.components.map(x=>`<p>${esc(`${x.label} · ${x.source}${x.version?` ${x.version}`:''}`)}</p>`).join('')}</div>`;
  }
  val03CalculationGroupsHtml=function(r){
    return r.groups.filter(g=>selectedQty(g)>0).map(g=>{
      const st=basisState(g); let basisUI='';
      if(st==='CONFLICT'){
        basisUI=`${vBanner('warning','Căn cứ giá đang mâu thuẫn','Chọn một căn cứ giá hoàn chỉnh có thẩm quyền và ghi lý do.')}<div class="valuation-source-list" data-composed-from="DS v2 / List Row,VRadio">${g.sources.map(b=>`<button type="button" class="val03-source-option ${g.selectedSource===b.id?'is-selected':''}" data-val03-source="${g.id}" data-val03-source-id="${b.id}" aria-pressed="${g.selectedSource===b.id}" data-ds-component="DS v2 / List Row"><span class="valuation-radio-control" aria-hidden="true"><span></span></span><span><strong>${esc(b.label)}</strong><small>${esc(val03SourcePriceText(b,g.uom))}</small></span></button>`).join('')}</div><label class="val03-reason" data-ds-component="VTextarea"><span>Lý do chọn căn cứ <b>*</b></span><textarea rows="3" data-val03-reason="${g.id}" placeholder="Nêu căn cứ để truy vết">${esc(g.reason||'')}</textarea></label>`;
      }else if(st==='MISSING') basisUI=vBanner('warning','Chưa đủ căn cứ','Phần này đang chờ căn cứ giá có thẩm quyền; không nhập giá tạm để đi tiếp.');
      else{ensureSingleBasis(g);const b=chosenBasis(g);basisUI=`${ds24InfoGroup('Căn cứ giá',ds24InfoRow('Căn cứ',b.label),'valuation-info-group valuation-info-group--wrap')}${componentsHtml(b)}`;}
      const c=calc(g),b=c?.src;
      const breakdown=c?`<div class="valuation-kv-stack" data-composed-from="DS v2 / Key-value Row">${ds24KeyValueRow('Giá nguồn quy đổi',`${fmt(c.baseVnd)}/${g.uom}`)}${b.unitLineDiscount?ds24KeyValueRow('Chiết khấu dòng',`− ${fmt(b.unitLineDiscount)}/${g.uom}`):''}${b.unitDocDiscount?ds24KeyValueRow('Chiết khấu phiếu',`− ${fmt(b.unitDocDiscount)}/${g.uom}`):''}${b.unitKnownCost?ds24KeyValueRow('Chi phí mua đã có',`+ ${fmt(b.unitKnownCost)}/${g.uom}`):''}${b.unitNonDeductibleVat?ds24KeyValueRow('Thuế không khấu trừ',`+ ${fmt(b.unitNonDeductibleVat)}/${g.uom}`):''}${ds24KeyValueRow('Giá nhập thực tế',`${fmt(c.unitActual)}/${g.uom}`,true)}${g.baseUom!==g.uom?ds24KeyValueRow(`Quy đổi ${g.baseUom}`,`${fmt(c.normalizedBaseCost)}/${g.baseUom}`):''}${ds24KeyValueRow('Giá trị lần này',fmt(c.value),true)}</div>`:'';
      return `<section class="valuation-evidence-group" data-valuation-basis="${escapeAttribute(g.valuationBasisKey)}">${valuationProductHeader({name:g.name,code:g.code,uom:g.uom,meta:duplicateBasisMeta(r,g)})}<div class="valuation-evidence-body">${basisUI}${breakdown}</div></section>`;
    }).join('');
  };
  val03EvidenceSheet=function(r=val03Current()){
    if(!val03EvidenceSheetOpen)return '';
    const invalid=!val03ScopeReady(r),title=val03HasSelectedConflict(r)?'Đối chiếu căn cứ giá':'Căn cứ giá và cách tính';
    const feedback=val03LastSourceChange?vBanner('warning','Căn cứ giá vừa thay đổi',`${val03LastSourceChange.name}: ${val03LastSourceChange.from} → ${val03LastSourceChange.to}`):bootstrapConflict(r)?vBanner('error','Không thể khởi tạo nhiều đơn giá khác nhau','Sản phẩm chưa có đơn giá chính thức; hãy xác nhận một căn cứ chuẩn hóa trước.'):invalid&&val03HasSelectedConflict(r)?vBanner('error','Cần hoàn tất căn cứ giá','Chọn căn cứ có thẩm quyền và ghi lý do cho phần đang mâu thuẫn.'):'';
    const body=val03CalculationGroupsHtml(r)||ioEmpty('Chưa có phạm vi để xem căn cứ','Chọn ít nhất một phạm vi hàng trước khi xem căn cứ giá và cách tính.');
    return `<div class="sheet-backdrop valuation-sheet-backdrop" data-val03-action="close-evidence-sheet"><section class="bottom-sheet val03-evidence-sheet valuation-evidence-sheet" data-ds-component="VBottomSheet" role="dialog" aria-modal="true" aria-label="${escapeAttribute(title)}" onclick="event.stopPropagation()"><div class="sheet-handle"></div><div class="sheet-title"><h3>${esc(title)}</h3></div><div class="sheet-divider"></div><div class="sheet-content">${feedback}${body}<div class="sheet-actions"><button class="button button--primary" type="button" data-val03-action="close-evidence-sheet" ${val03HasSelectedConflict(r)&&!val03ScopeReady(r)?'disabled':''} data-ds-component="VButton">${val03HasSelectedConflict(r)?'Xong':'Đóng'}</button></div></div></section></div>`;
  };

  val03ReviewGroupsHtml=function(r){
    const content=r.groups.filter(g=>selectedQty(g)>0).map(g=>{
      const c=calc(g),facts=`<div class="valuation-product-facts" data-composed-from="DS v2 / Key-value Row">${ds24KeyValueRow('Giá nhập thực tế',c?`${fmt(c.unitActual)}/${g.uom}`:'—')}${g.baseUom!==g.uom&&c?ds24KeyValueRow(`Quy đổi ${g.baseUom}`,`${fmt(c.normalizedBaseCost)}/${g.baseUom}`):''}${ds24KeyValueRow('Căn cứ giá',val03SourceDetail(g))}${g.officialCostStatus==='NONE'&&c?ds24KeyValueRow('Đơn giá chính thức khởi tạo',`${fmt(c.normalizedBaseCost)}/${g.baseUom}`):''}</div>`;
      const slices=g.slices.filter(s=>s.selected&&s.pendingQty>0).map(s=>{const q=Math.min(Number(s.selectedQty)||0,s.pendingQty),ad=val03SelectedAvailability(g,s),effect=ad>0?`+${ad} ${g.uom}`:s.availabilityNote;return valuationReadOnlyChild({title:val03ScopeLabel(g,s),subtitle:`${s.stateLabel} · ${q} ${g.uom}`,trailing:`<span class="valuation-child-value"><small>Khả dụng</small><strong>${esc(effect)}</strong></span>`});}).join('');
      return `<div class="valuation-product-group" data-valuation-basis="${escapeAttribute(g.valuationBasisKey)}">${valuationProductHeader({name:g.name,code:g.code,uom:g.uom,value:c?fmt(c.value):'—',meta:duplicateBasisMeta(r,g)})}${facts}<div class="valuation-child-list">${slices}</div></div>`;
    }).join('');
    return ds24GroupedCollection(content,'valuation-product-collection valuation-review-collection','DS v2 / Icon,DS v2 / Key-value Row,VText');
  };
  val03ResultGroupsHtml=function(res){
    const content=(res.groups||[]).map(g=>{
      const boot=g.officialCostBootstrapStatus==='INITIALIZED'?`Đã khởi tạo · ${fmt(g.normalizedBaseCost)}/${g.baseUom}`:g.officialCostBootstrapStatus==='ALREADY_INITIALIZED'?'Đã có trước đó · không ghi đè':'';
      const facts=`<div class="valuation-product-facts" data-composed-from="DS v2 / Key-value Row">${ds24KeyValueRow('Giá nhập thực tế',`${fmt(g.unitActual)}/${g.uom}`)}${g.baseUom!==g.uom?ds24KeyValueRow(`Quy đổi ${g.baseUom}`,`${fmt(g.normalizedBaseCost)}/${g.baseUom}`):''}${boot?ds24KeyValueRow('Đơn giá chính thức',boot):''}</div>`;
      const slices=g.slices.map(s=>valuationReadOnlyChild({title:s.lot?`Lô ${s.lot}`:'Không theo lô',subtitle:`${s.state} · ${s.qty} ${g.uom} · ${fmt(s.value)}`,trailing:`<span class="valuation-child-value"><small>Khả dụng</small><strong>${esc(s.availabilityDelta>0?`+${s.availabilityDelta} ${g.uom}`:s.availabilityNote)}</strong></span>`})).join('');
      return `<div class="valuation-product-group">${valuationProductHeader({name:g.name,code:g.code,uom:g.uom,value:fmt(g.value),meta:g.receiptItemRef})}${facts}<div class="valuation-child-list">${slices}</div></div>`;
    }).join('');
    return ds24GroupedCollection(content,'valuation-product-collection valuation-result-collection','DS v2 / Icon,DS v2 / Key-value Row,VText');
  };

  const old014=render014IV03;
  render014IV03=function(state){
    if(activeFlowId!=='UIF-03')return old014(state);
    if(state==='FINANCIAL_MASKED')return appShell({title:'Hàng chờ xác nhận giá nhập',body:ioEmpty('Không có quyền xem dữ liệu tài chính','Yêu cầu quyền tài chính phù hợp để mở công việc xác nhận giá.'),back:false});
    return old014(state);
  };
  const old015=render015IV03;
  render015IV03=function(state){
    if(activeFlowId!=='UIF-03')return old015(state);
    reviewTokens=null;
    if(state==='FINANCIAL_MASKED')return appShell({title:'Chọn hàng cần xác nhận giá',body:ioEmpty('Không có quyền xem dữ liệu tài chính','Dữ liệu giá và căn cứ không được đưa vào DOM khi chưa có quyền.'),back:true});
    return old015(state);
  };
  render017IV03=function(state){
    if(activeFlowId!=='UIF-03')return renderGeneric(screens.find(s=>s.id==='SCR-017'),state);
    const r=val03Current();
    if(state==='PERMISSION_DENIED'||state==='FINANCIAL_MASKED')return appShell({title:'Rà soát xác nhận giá',body:ioEmpty('Không có quyền xem dữ liệu tài chính','Dữ liệu giá và căn cứ không được đưa vào DOM khi chưa có quyền.'),centered:true});
    if(!reviewTokens)reviewTokens=currentTokenMap(r);
    const stale=state==='SOURCE_CHANGED'||tokenStale(r);
    const summary=`${ds24InfoGroup('Phiếu nhận',`${ds24InfoRow('Phiếu',r.receipt)}${ds24InfoRow('Nhà cung cấp',r.supplier)}`,'valuation-info-group')}<div class="valuation-total-strip" data-composed-from="DS v2 / Key-value Row">${ds24KeyValueRow('Tổng giá trị sẽ ghi',fmt(val03TotalValue(r)),true)}</div>`;
    if(stale){val03EvidenceSheetOpen=true;return appShell({title:'Rà soát xác nhận giá',body:`${vBanner('warning','Căn cứ giá hoặc phạm vi đã thay đổi','Không thể xác nhận trên preview cũ. Đối chiếu lại căn cứ hiện hành trước khi tiếp tục.')}${summary}${ds24SectionTitle('Nội dung sẽ xác nhận',`${val03SelectedGroupCount(r)} nhóm căn cứ`)}${val03ReviewGroupsHtml(r)}${val03EvidenceSheet(r)}`});}
    const body=`${summary}${ds24SectionTitle('Nội dung sẽ xác nhận',`${val03SelectedGroupCount(r)} nhóm căn cứ`)}${val03ReviewGroupsHtml(r)}<button type="button" class="io-text-action valuation-text-action" data-val03-action="open-evidence-sheet" data-ds-component="DS v2 / Link">Xem căn cứ giá và cách tính</button>${val03EvidenceSheet(r)}`;
    return appShell({title:'Rà soát xác nhận giá',body,actions:primaryFooter('Xác nhận giá trị','data-val03-action="confirm-value"',!val03ScopeReady(r))});
  };
  render019IV03=function(state){
    if(activeFlowId!=='UIF-03')return renderGeneric(screens.find(s=>s.id==='SCR-019'),state);
    const res=val03ResultSnapshot();
    if(state==='PROCESSING')return appShell({title:'Kết quả xác nhận giá',body:loadingBody(),centered:true,back:false});
    if(state==='UNKNOWN'){const op=res.operationId||`VAL03-${res.receipt||'UNKNOWN'}`;const attrs=`data-v350-action="handoff-unknown" data-source-flow="UIF-03" data-operation="${escapeAttribute(op)}" data-scope="${escapeAttribute(res.receipt||'BJ03 direct valuation')}"`;return appShell({title:'Đang xác minh kết quả',body:ioResult('Chưa xác định thao tác đã ghi hay chưa','Không gửi lại xác nhận. Chuyển đúng lần xử lý này sang luồng xác minh kết quả.',[['Phiếu nhận',res.receipt],['Trạng thái','Đang xác minh']],'warning'),centered:true,back:false,actions:primaryFooter('Chuyển sang xác minh',attrs)});}
    if(state==='REJECTED_EXECUTION')return appShell({title:'Kết quả xác nhận giá',body:ioResult('Chưa ghi nhận giá trị','Không có thay đổi. Kiểm tra lại phạm vi và căn cứ giá hiện hành.',[['Phiếu nhận',res.receipt],['Tác động','Không thay đổi']],'warning'),centered:true,back:false,actions:primaryFooter('Xem lại hàng cần xác nhận','data-val03-action="result-to-scope"')});
    const actionable=val03ActionablePairs(val03Current()).length,waiting=val03WaitingPairs(val03Current()).length,waitingNote=waiting&&!actionable?vBanner('info','Phần còn lại đang chờ căn cứ','Bạn đã hoàn tất phần có thể xử lý.'):'';
    const overview=ds24InfoGroup('Kết quả',`${ds24InfoRow('Phiếu nhận',res.receipt)}${ds24InfoRow('Ngày nghiệp vụ',res.businessDate||'—')}${ds24InfoRow('Ghi nhận lúc',res.recordedAt||'—')}${ds24KeyValueRow('Giá trị đã ghi',fmt(res.totalValue),true)}`,'valuation-info-group valuation-result-overview');
    const body=`<div class="io-result val03-result">${resultHero('Đã xác nhận giá','Giá trị đã được ghi cho đúng phạm vi đã chọn.')}${overview}${ds24SectionTitle('Phạm vi đã ghi')}${val03ResultGroupsHtml(res)}${waitingNote}</div>`;
    return appShell({title:'Kết quả xác nhận giá',body,centered:true,back:false,actions:primaryFooter(actionable?'Tiếp tục xác nhận':'Về danh sách',actionable?'data-val03-action="continue-remaining"':'data-val03-action="result-to-queue"')});
  };
  if(typeof renderers!=='undefined'){
    renderers['SCR-014']=render014IV03;renderers['SCR-015']=render015IV03;renderers['SCR-017']=render017IV03;renderers['SCR-019']=render019IV03;
  }

  // Public trace helpers for QA and fresh-eye review.
  window.val03V397={basisState,currentTokenMap,tokenStale,confirmationAmount,bootstrapConflict,normalizedBaseCost};
  if(window.__VET45_PROTOTYPE__) window.__VET45_PROTOTYPE__.version='3.9.7';
})();
