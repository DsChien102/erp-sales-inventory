/* VET45 Theme 7 v3.13.0 — Inventory valuation design parity
 * Parent: v3.12.0 specification baseline / v3.10.1 prototype carry-forward
 * Scope: UIF-03, UIF-13, UIF-14 only. Rebinds renderers last; no cross-flow mutation.
 */
(()=>{
  if(typeof renderers==='undefined') return;
  const money=n=>`${Number(n||0)<0?'− ':''}${Math.abs(Math.round(Number(n)||0)).toLocaleString('vi-VN')} đ`;
  const signed=n=>`${Number(n||0)>0?'+ ':Number(n||0)<0?'− ':''}${Math.abs(Math.round(Number(n)||0)).toLocaleString('vi-VN')} đ`;
  const qty=(g)=>g.slices.filter(s=>s.pendingQty>0).reduce((n,s)=>n+Number(s.pendingQty||0),0);
  const pendingGroups=(r)=>r.groups.filter(g=>qty(g)>0);
  const entryType=(r)=>r.v313EntryType||'DOCUMENT';
  const entryLabel=(r)=>entryType(r)==='QUICK'?'Nhập nhanh':'Theo chứng từ';
  const stable=(value)=>{let h=2166136261>>>0;for(const c of String(value)){h^=c.charCodeAt(0);h=Math.imul(h,16777619)>>>0;}return `fixture-v313-${h.toString(16)}`;};
  const info=(title,rows)=>ds24InfoGroup(title,rows,'valuation-info-group v313-info-group');
  const key=(label,value,em=false)=>ds24KeyValueRow(label,value,em);
  const row=(args)=>ds24ListRow({...args,density:args.density||'Compact'});
  const heading=(title,meta='')=>`<div class="v313-section-heading"><h2>${esc(title)}</h2>${meta?`<span>${esc(meta)}</span>`:''}</div>`;
  const linkButton=(label,attrs)=>`<button type="button" class="v313-text-action" ${attrs} data-ds-component="DS v2 / Link">${esc(label)}</button>`;
  const field=(label,control,helper='')=>`<label class="v313-field" data-ds-component="VTextField"><span class="v313-field__label">${esc(label)}</span>${control}${helper?`<small>${esc(helper)}</small>`:''}</label>`;
  const select=(attrs,options)=>`<select ${attrs} class="v313-control" data-ds-component="VSelect">${options}</select>`;
  const input=(attrs,value='',type='text',placeholder='')=>`<input ${attrs} class="v313-control" type="${type}" value="${escapeAttribute(value)}" placeholder="${escapeAttribute(placeholder)}"/>`;
  const summary=(title,body,tone='Neutral')=>`<section class="v313-summary v313-summary--${String(tone).toLowerCase()}" data-ds-component="DS v2 / Summary Card" data-figma-node="525:552" data-ds-prop-tone="${tone}"><h2>${esc(title)}</h2><p>${esc(body)}</p></section>`;
  const readiness=(title,body,tone='Warning')=>`<div class="v313-readiness v313-readiness--${String(tone).toLowerCase()}" data-ds-component="DS v2 / Readiness Item" data-figma-node="526:4442"><span class="v313-readiness__icon">${icon(tone==='Success'?'checkCircle':'alert','icon--sm')}</span><span><strong>${esc(title)}</strong><small>${esc(body)}</small></span></div>`;
  const sheet=(title,content,actions='')=>`<div class="v313-sheet-layer" data-v313-sheet-backdrop><div class="v313-sheet-backdrop"></div><section class="v313-sheet" data-ds-component="VBottomSheet" data-figma-node="4695:6353"><div class="v313-sheet__handle"></div><h2>${esc(title)}</h2><div class="v313-sheet__content">${content}</div>${actions?`<div class="v313-sheet__actions">${actions}</div>`:''}</section></div>`;
  const button=(label,attrs,kind='primary',disabled=false)=>`<button type="button" class="button button--${kind}" ${attrs} data-ds-component="VButton" ${disabled?'disabled':''}>${esc(label)}</button>`;

  // ---------------------------------------------------------------------------
  // BJ03 — Xác lập giá trị nhập ban đầu
  // ---------------------------------------------------------------------------
  if(typeof val03Receipts!=='undefined'){
    const types={"VAL03-R1":"DOCUMENT","VAL03-R2":"QUICK","VAL03-R3":"QUICK","VAL03-R4":"DOCUMENT"};
    val03Receipts.forEach(r=>{r.v313EntryType=types[r.id]||'DOCUMENT';});
  }
  let v313Val03Filter='ALL';
  let v313Val03Sheet=null;
  function v313Val03GroupState(r,g){
    const st=val03EvidenceState(g);
    if(st==='READY') return 'READY';
    if(st==='CONFLICT') return entryType(r)==='DOCUMENT'?'COMMERCIAL_CONFLICT':'DIRECT_CONFLICT';
    return entryType(r)==='QUICK'?'DIRECT_MISSING':'COMMERCIAL_MISSING';
  }
  function v313Val03ReceiptState(r){
    const states=pendingGroups(r).map(g=>v313Val03GroupState(r,g));
    if(states.some(x=>x==='COMMERCIAL_CONFLICT'||x==='DIRECT_CONFLICT')) return 'CONFLICT';
    if(states.length && states.every(x=>x.includes('MISSING'))) return 'MISSING';
    return 'READY';
  }
  function v313Val03SelectedGroups(r=val03Current()){return pendingGroups(r).filter(g=>g.slices.some(s=>s.selected&&s.pendingQty>0));}
  function v313Val03SelectGroup(g,on){g.slices.filter(s=>s.pendingQty>0).forEach(s=>{s.selected=on;s.selectedQty=s.pendingQty;s.partialOpen=false;});}
  function v313Val03ClearSelection(r=val03Current()){r.groups.forEach(g=>v313Val03SelectGroup(g,false));}
  function v313Val03Breakdown(g){
    const source=val03Source(g); if(!source) return '';
    const unit=source.unitPrice*source.fxRate;
    const actual=unit-(source.unitLineDiscount||0)-(source.unitDocDiscount||0)+(source.unitKnownCost||0)+(source.unitNonDeductibleVat||0);
    return `<div class="v313-kv">${key(source.currency==='VND'?'Giá mua':'Giá mua quy đổi',`${money(unit)}/${g.uom}`)}${source.unitLineDiscount?key('Chiết khấu dòng',`− ${money(source.unitLineDiscount)}/${g.uom}`):''}${source.unitDocDiscount?key('Chiết khấu chứng từ',`− ${money(source.unitDocDiscount)}/${g.uom}`):''}${source.unitKnownCost?key('Chi phí mua đã biết',`+ ${money(source.unitKnownCost)}/${g.uom}`):''}${source.unitNonDeductibleVat?key('Thuế tính vào giá trị',`+ ${money(source.unitNonDeductibleVat)}/${g.uom}`):''}${key('Đơn giá ghi nhận ban đầu',`${money(actual)}/${g.uom}`,true)}</div>`;
  }
  function v313Val03BasisLabel(g){const s=val03Source(g);return s?s.label:'Chưa có căn cứ';}
  function v313Val03DirectSheet(r,g){
    const content=`${vBanner('info','Căn cứ cho nhập nhanh','Giá này chỉ dùng để xác lập giá trị ban đầu của lượng hàng đã nhận. Nếu chứng từ mua xuất hiện sau, chênh lệch được ghi bằng điều chỉnh giá trị.','','Compact')}
      ${field('Đơn giá mua',input('data-v313-basis-price','', 'number','0'),'Nhập theo đơn vị '+g.uom)}
      <div class="v313-field"><span class="v313-field__label">Cách hiểu giá</span><div class="v313-segment" data-ds-component="VSegmentedControl" data-figma-node="1049:9619"><button type="button" class="is-selected" data-v313-tax-mode="INCLUDED">Đã gồm thuế</button><button type="button" data-v313-tax-mode="EXCLUDED">Chưa gồm thuế</button></div></div>
      <div data-v313-tax-amount-wrap hidden>${field('Thuế trên giá mua',input('data-v313-basis-tax','0','number','0'),'Theo chính sách hộ kinh doanh hiện tại, phần thuế này được tính vào giá trị hàng nhập.')}</div>
      ${field('Nguồn căn cứ',input('data-v313-basis-source','','text','Ví dụ: Xác nhận giá từ nhà cung cấp'))}
      ${field('Ngày căn cứ',input('data-v313-basis-date','24/09/2026','text','dd/mm/yyyy'))}
      ${field('Tham chiếu / bằng chứng',input('data-v313-basis-ref','','text','Mã báo giá, email, ghi chú...'))}
      ${field('Lý do xác lập trực tiếp',input('data-v313-basis-reason','','text','Nêu ngắn gọn lý do'),'Bắt buộc khi chưa có chứng từ mua có cấu trúc.')}`;
    const actions=`${button('Hủy','data-v313-val03-sheet="close"','secondary')}${button('Lưu căn cứ','data-v313-val03-sheet="save"')}`;
    return sheet(`Thêm căn cứ giá · ${g.name}`,content,actions);
  }
  function v313Val03Group(r,g){
    const st=v313Val03GroupState(r,g),pending=qty(g),selected=v313Val03SelectedGroups(r).includes(g);
    const subtitle=`${pending} ${g.uom} đang chờ giá trị${g.tracking==='LOT'?` · ${g.slices.filter(s=>s.pendingQty>0).length} lô`:''}`;
    if(st==='READY'){
      const s=val03Source(g); const calc=v313Val03Breakdown(g);
      return `<section class="v313-work-section ${selected?'is-selected':''}" data-v313-group="${g.id}">${row({title:g.name,subtitle,trailing:selected?icon('checkCircle','icon--sm'):'',leading:null,type:'Selection',state:selected?'Selected':'Default',attrs:`data-v313-val03-select="${g.id}"`})}<div class="v313-section-body">${info('Căn cứ giá',ds24InfoRow('Nguồn',s?.label||'—')+(s?.currency!=='VND'?ds24InfoRow('Tỷ giá',s?.fxLabel||'—'):''))}${calc}</div></section>`;
    }
    if(st==='COMMERCIAL_CONFLICT') return `<section class="v313-work-section">${row({title:g.name,subtitle,trailing:ds24Badge('Cần đối chiếu','Warning'),leading:null,type:'Status',interactive:false})}<div class="v313-section-body">${vBanner('warning','Căn cứ mua hàng đang mâu thuẫn','Giá trên các căn cứ thương mại chưa thống nhất. Hãy đối chiếu chứng từ mua trước khi xác lập giá trị cho dòng này.')}</div></section>`;
    if(st==='COMMERCIAL_MISSING') return `<section class="v313-work-section">${row({title:g.name,subtitle,trailing:ds24Badge('Cần căn cứ','Warning'),leading:null,type:'Status',interactive:false})}<div class="v313-section-body">${vBanner('warning','Chưa đủ căn cứ mua hàng','Dòng nhận theo chứng từ chưa có căn cứ giá đủ điều kiện. Khi căn cứ được bổ sung, công việc sẽ tự cập nhật.')}</div></section>`;
    if(st==='DIRECT_MISSING') return `<section class="v313-work-section">${row({title:g.name,subtitle,trailing:ds24Badge('Chưa có căn cứ','Neutral'),leading:null,type:'Status',interactive:false})}<div class="v313-section-body"><p class="v313-helper">Nhập nhanh không cần chờ Theme Mua. Kế toán có thể lập căn cứ giá trực tiếp có dấu vết.</p>${button('Thêm căn cứ giá',`data-v313-val03-add-basis="${g.id}"`,'secondary')}</div></section>`;
    return `<section class="v313-work-section">${row({title:g.name,subtitle,trailing:ds24Badge('Cần kiểm tra','Warning'),leading:null,type:'Status',interactive:false})}</section>`;
  }
  function v313Val03CanReview(r=val03Current()){
    const sel=v313Val03SelectedGroups(r);return sel.length>0&&sel.every(g=>v313Val03GroupState(r,g)==='READY');
  }
  function v313Val03SaveBasis(groupId){
    const r=val03Current(),g=r.groups.find(x=>x.id===groupId); if(!g) return false;
    const root=document.querySelector('.v313-sheet');
    const price=Number(root?.querySelector('[data-v313-basis-price]')?.value||0);
    const sourceLabel=String(root?.querySelector('[data-v313-basis-source]')?.value||'').trim();
    const date=String(root?.querySelector('[data-v313-basis-date]')?.value||'').trim();
    const ref=String(root?.querySelector('[data-v313-basis-ref]')?.value||'').trim();
    const reason=String(root?.querySelector('[data-v313-basis-reason]')?.value||'').trim();
    const taxMode=root?.querySelector('[data-v313-tax-mode].is-selected')?.dataset.v313TaxMode||'INCLUDED';
    const tax=taxMode==='EXCLUDED'?Number(root?.querySelector('[data-v313-basis-tax]')?.value||0):0;
    if(price<=0||!sourceLabel||!reason){root?.classList.add('has-validation-error');return false;}
    const id=`DIRECT-${g.id}-${Date.now()}`;
    const components=[{type:'PURCHASE_PRICE',label:'Giá mua',source:sourceLabel,version:date||'Hiện hành',amount:price}];
    if(tax)components.push({type:'NON_RECOVERABLE_TAX',label:'Thuế tính vào giá trị',source:sourceLabel,version:date||'Hiện hành',amount:tax});
    g.sources=[{id,label:`${sourceLabel}${date?` · ${date}`:''}`,version:'v1',basisVersion:1,basisHash:stable(`${id}|${price}|${tax}|${date}`),authoritativeValueHash:stable(`${price+tax}`),unitPrice:price,currency:'VND',fxRate:1,fxLabel:'VND',unitLineDiscount:0,unitDocDiscount:0,unitKnownCost:0,unitNonDeductibleVat:tax,components,evidenceRefs:[ref||reason],provenance:components.map(c=>`${c.label} · ${c.source}`),directReason:reason,taxMode,sourceDate:date,reference:ref}];
    g.selectedSource=id;r.sourceVersion=Number(r.sourceVersion||0)+1;v313Val03SelectGroup(g,true);return true;
  }
  function v313Val03Commit(){
    const r=val03Current(),groups=[];let totalValue=0,totalQty=0;
    for(const g of v313Val03SelectedGroups(r)){
      const c=val03Calc(g);if(!c)continue;
      const lines=[];let groupQty=0,groupValue=0;
      for(const s of g.slices.filter(x=>x.selected&&x.pendingQty>0)){
        const q=Number(s.pendingQty||0),amount=Math.round(Number(c.unitActual||0)*q);groupQty+=q;groupValue+=amount;
        lines.push({scopeKey:s.scopeKey,lot:s.lot,state:s.stateLabel,qty:q,value:amount});
      }
      groups.push({name:g.name,code:g.code,uom:g.uom,qty:groupQty,value:groupValue,unitInitial:c.unitActual,source:val03SourceDetail(g),slices:lines});
      totalQty+=groupQty;totalValue+=groupValue;
    }
    val03LastResult={operationId:`VAL-260925-${String(val03OperationSeq++).padStart(3,'0')}`,receipt:r.receipt,supplier:r.supplier,businessDate:r.receivedAt,groups,totalValue,totalQty,dirtyScope:groups.map(g=>`${g.name} · kỳ ${r.receivedAt.slice(3)}`)};
    for(const g of v313Val03SelectedGroups(r)) for(const s of g.slices.filter(x=>x.selected&&x.pendingQty>0)){const q=s.pendingQty,amount=Math.round((val03Calc(g)?.unitActual||0)*q);s.pendingQty=0;s.confirmedQty=Number(s.confirmedQty||0)+q;s.confirmedValue=Number(s.confirmedValue||0)+amount;s.scopeVersion=Number(s.scopeVersion||0)+1;s.selected=false;s.selectedQty=0;}
    val03ReviewSourceVersion=null;return val03LastResult;
  }
  val03Commit=v313Val03Commit;

  function render014V313(state){
    if(activeFlowId!=='UIF-03')return renderGeneric(screens.find(s=>s.id==='SCR-014'),state);
    if(state==='LOADING')return appShell({title:'Hàng chờ xác lập giá trị',body:loadingBody(),centered:true,back:false});
    if(state==='PERMISSION_DENIED')return appShell({title:'Hàng chờ xác lập giá trị',body:deniedBody(),centered:true,back:false});
    const q=String(val03Query||'').toLocaleLowerCase('vi');
    const rows=val03Receipts.filter(r=>pendingGroups(r).length).filter(r=>!q||`${r.receipt} ${r.supplier}`.toLocaleLowerCase('vi').includes(q)).filter(r=>{
      const st=v313Val03ReceiptState(r);return v313Val03Filter==='ALL'||(v313Val03Filter==='READY'&&st==='READY')||(v313Val03Filter==='ISSUE'&&st!=='READY');
    }).map(r=>{
      const st=v313Val03ReceiptState(r),count=pendingGroups(r).length;
      const trailing=st==='CONFLICT'?ds24Badge('Cần đối chiếu','Warning'):st==='MISSING'?ds24Badge('Cần căn cứ','Neutral'):'';
      return row({title:r.receipt,subtitle:`${r.supplier} · ${entryLabel(r)} · ${count} dòng chờ`,trailing,leading:null,attrs:`data-v313-val03-receipt="${r.id}"`,type:'Navigation'});
    }).join('');
    const body=`${ds24Search(val03Query,'data-val03-search','Phiếu nhận hoặc nhà cung cấp')}<div class="ds24-chip-scroll">${ds24Chip('ALL','Tất cả',v313Val03Filter==='ALL','data-v313-val03-filter')}${ds24Chip('READY','Có thể xác lập',v313Val03Filter==='READY','data-v313-val03-filter')}${ds24Chip('ISSUE','Cần xử lý',v313Val03Filter==='ISSUE','data-v313-val03-filter')}</div>${rows?`<section class="ds24-list-stack v313-list">${rows}</section>`:ioEmpty('Không có công việc phù hợp','Đổi từ khóa hoặc bộ lọc để xem công việc khác.')}`;
    return appShell({title:'Hàng chờ xác lập giá trị',body,back:false});
  }
  function render015V313(state){
    if(activeFlowId!=='UIF-03')return renderGeneric(screens.find(s=>s.id==='SCR-015'),state);const r=val03Current();
    if(state==='LOADING')return appShell({title:'Xác lập giá trị nhập ban đầu',body:loadingBody(),centered:true});
    if(state==='PERMISSION_DENIED')return appShell({title:'Xác lập giá trị nhập ban đầu',body:deniedBody(),centered:true});
    const context=info('Phiếu nhận',ds24InfoRow('Phiếu',r.receipt)+ds24InfoRow('Nhà cung cấp',r.supplier)+ds24InfoRow('Ngày nhận',r.receivedAt)+ds24InfoRow('Hình thức',entryLabel(r)));
    const work=pendingGroups(r).map(g=>v313Val03Group(r,g)).join('');
    const selected=v313Val03SelectedGroups(r);const total=selected.reduce((n,g)=>n+(val03Calc(g)?.value||0),0);
    const selection=selected.length?summary('Sẽ xác lập',`${selected.length} dòng hàng · ${money(total)}`,'Brand'):'';
    const body=`${state==='SOURCE_CHANGED'?vBanner('warning','Căn cứ đã thay đổi','Kiểm tra lại giá và cấu thành trước khi tiếp tục.'):''}${context}${heading('Hàng chờ giá trị')}${work}${selection}${v313Val03Sheet?v313Val03DirectSheet(r,r.groups.find(g=>g.id===v313Val03Sheet)):''}`;
    return appShell({title:'Xác lập giá trị nhập ban đầu',body,actions:primaryFooter('Rà soát', 'data-v313-val03-review',!v313Val03CanReview(r))});
  }
  function render016V313(){return render015V313('READY');}
  function render017V313(state){
    if(activeFlowId!=='UIF-03')return renderGeneric(screens.find(s=>s.id==='SCR-017'),state);const r=val03Current();
    if(state==='PERMISSION_DENIED')return appShell({title:'Rà soát giá trị nhập ban đầu',body:deniedBody(),centered:true});
    const stale=state==='SOURCE_CHANGED'||val03ReviewSourceVersion==null||Number(val03ReviewSourceVersion)!==Number(r.sourceVersion);
    if(stale)return appShell({title:'Rà soát giá trị nhập ban đầu',body:`${vBanner('warning','Căn cứ đã thay đổi','Kết quả rà soát cũ không còn hiệu lực. Quay lại kiểm tra căn cứ hiện hành.')}${info('Phiếu nhận',ds24InfoRow('Phiếu',r.receipt)+ds24InfoRow('Nhà cung cấp',r.supplier))}`,actions:primaryFooter('Kiểm tra lại','data-v313-val03-back')});
    const sections=v313Val03SelectedGroups(r).map(g=>{const c=val03Calc(g);return `<section class="v313-review-section">${heading(g.name,`${c?.qty||0} ${g.uom}`)}${info('Căn cứ',ds24InfoRow('Nguồn',val03SourceDetail(g)))}${v313Val03Breakdown(g)}${key('Giá trị sẽ ghi',money(c?.value||0),true)}</section>`;}).join('');
    const total=v313Val03SelectedGroups(r).reduce((n,g)=>n+(val03Calc(g)?.value||0),0);
    const body=`${info('Phiếu nhận',ds24InfoRow('Phiếu',r.receipt)+ds24InfoRow('Nhà cung cấp',r.supplier)+ds24InfoRow('Ngày nhận',r.receivedAt))}${sections}${summary('Tổng giá trị nhập ban đầu',money(total),'Brand')}${linkButton('Chỉnh sửa căn cứ','data-v313-val03-back')}`;
    return appShell({title:'Rà soát giá trị nhập ban đầu',body,actions:primaryFooter('Xác nhận giá trị','data-v313-val03-confirm')});
  }
  function render019V313(state){
    if(activeFlowId!=='UIF-03')return renderGeneric(screens.find(s=>s.id==='SCR-019'),state);const res=val03LastResult||{receipt:val03Current().receipt,supplier:val03Current().supplier,groups:[],totalValue:0,totalQty:0,dirtyScope:[]};
    if(state==='PROCESSING')return appShell({title:'Kết quả xác lập giá trị',body:loadingBody(),centered:true,back:false});
    if(state==='UNKNOWN'){const attrs=`data-v350-action="handoff-unknown" data-source-flow="UIF-03" data-operation="${escapeAttribute(res.operationId||'VAL-UNKNOWN')}" data-scope="${escapeAttribute(res.receipt||'')}"`;return appShell({title:'Đang xác minh kết quả',body:ioResult('Chưa xác định giá trị đã được ghi hay chưa','Không gửi lại lệnh xác nhận. Chuyển đúng lần xử lý này sang xác minh kết quả.',[['Phiếu nhận',res.receipt],['Trạng thái','Đang xác minh']],'warning'),centered:true,back:false,actions:primaryFooter('Chuyển sang xác minh',attrs)});}
    if(state==='REJECTED_EXECUTION')return appShell({title:'Kết quả xác lập giá trị',body:ioResult('Chưa ghi giá trị nhập ban đầu','Không có thay đổi. Kiểm tra lại căn cứ hiện hành.',[['Phiếu nhận',res.receipt],['Tác động','Không thay đổi']],'warning'),centered:true,back:false,actions:primaryFooter('Xem lại công việc','data-v313-val03-result-back')});
    const remaining=pendingGroups(val03Current()).length;
    const rows=(res.groups||[]).map(g=>key(g.name,`${g.qty} ${g.uom} · ${money(g.value)}`)).join('');
    const body=`<div class="io-result">${resultHero('Đã xác lập giá trị nhập ban đầu','Giá trị đã được ghi cho lượng hàng đã rà soát. Giá vốn sẽ được cập nhật ở công việc giá vốn.')}${info('Kết quả',ds24InfoRow('Phiếu nhận',res.receipt)+ds24InfoRow('Số dòng đã xác lập',String(res.groups?.length||0))+ds24InfoRow('Số lượng',String(res.totalQty||0))+key('Tổng giá trị đã ghi',money(res.totalValue),true)+ds24InfoRow('Giá vốn','Cần cập nhật'))}${res.groups?.length?`<div class="v313-kv">${rows}</div>`:''}${remaining?vBanner('info','Còn hàng chờ giá trị',`${remaining} dòng của phiếu này chưa đủ điều kiện hoặc chưa được chọn trong lần xử lý.`,'','Compact'):''}</div>`;
    return appShell({title:'Kết quả xác lập giá trị',body,centered:true,back:false,actions:primaryFooter(remaining?'Tiếp tục xử lý':'Về danh sách',remaining?'data-v313-val03-result-back':'data-v313-val03-result-list')});
  }

  // ---------------------------------------------------------------------------
  // BJ13 — Điều chỉnh giá trị hàng nhập
  // ---------------------------------------------------------------------------
  let v313Val13Filter='ALL';
  function v313Val13ImpactLabel(t){const n=Number(t.normalizedAmount||0);return n<0?'Giảm giá trị':n>0?'Tăng giá trị':'Không đổi';}
  function v313Val13Source(t){return info('Nguồn điều chỉnh',ds24InfoRow('Nguồn',t.sourceRef)+ds24InfoRow('Loại',t.component)+ds24InfoRow('Đối tác',t.supplier)+(t.currency!=='VND'?ds24InfoRow('Giá trị nguồn',val13FmtSourceAmount(t))+ds24InfoRow('Tỷ giá',t.fxLabel):'')+key('Giá trị điều chỉnh',signed(t.normalizedAmount),true));}
  function v313Val13Targets(t){
    return (t.targets||[]).map(x=>row({title:x.product,subtitle:`${x.receipt} · ${x.qty} ${x.uom}${x.lot?` · Lô ${x.lot}`:''}`,trailing:t.targetScopeMode==='FIXED'?ds24Badge('Theo nguồn','Neutral'):(x.selected?icon('checkCircle','icon--sm'):''),leading:null,type:t.targetScopeMode==='FIXED'?'Status':'Selection',interactive:t.targetScopeMode!=='FIXED',state:x.selected?'Selected':'Default',attrs:t.targetScopeMode==='FIXED'?'':`data-val13-target="${x.id}"`})).join('');
  }
  function v313Val13Method(t){const opts=`<option value="">Chọn cách phân bổ</option>`+(t.allowedMethods||[]).map(m=>`<option value="${m.id}" ${m.id===t.selectedMethod?'selected':''}>${esc(m.label)}</option>`).join('');return field('Cách phân bổ',select('data-val13-method',opts));}
  function v313Val13Preview(t){
    const p=val13Preview(t);if(!p.length)return vBanner('info','Chưa có preview','Chọn phạm vi và cách phân bổ hợp lệ để xem kết quả trước khi rà soát.','','Compact');
    const rows=p.map(x=>key(`${x.product} · ${x.receipt}`,signed(x.allocatedAmount))).join('');
    return `<section class="v313-preview">${heading('Kết quả phân bổ',`${p.length} dòng`)}<div class="v313-kv">${rows}${key('Tổng phân bổ',signed(p.reduce((n,x)=>n+x.allocatedAmount,0)),true)}</div></section>`;
  }
  function render085V313(state){
    if(activeFlowId!=='UIF-13')return renderGeneric(screens.find(s=>s.id==='SCR-085'),state);
    if(state==='LOADING')return appShell({title:'Điều chỉnh giá trị hàng nhập',body:loadingBody(),centered:true,back:false});
    if(state==='PERMISSION_DENIED')return appShell({title:'Điều chỉnh giá trị hàng nhập',body:deniedBody(),centered:true,back:false});
    const q=String(val13Query||'').toLocaleLowerCase('vi');const tasks=val13Tasks.filter(t=>t.status!=='COMPLETED').filter(t=>!q||`${t.sourceRef} ${t.supplier} ${t.component}`.toLocaleLowerCase('vi').includes(q)).filter(t=>v313Val13Filter==='ALL'||(v313Val13Filter==='ACTIONABLE'&&t.status==='ACTIONABLE')||(v313Val13Filter==='WAITING'&&t.status==='WAITING'));
    const rows=tasks.map(t=>{const wait=t.status==='WAITING';return row({title:t.sourceRef.replace(/ · dòng \d+$/,''),subtitle:`${t.component} · ${t.supplier}${t.normalizedAmount!=null?` · ${signed(t.normalizedAmount)}`:''}`,trailing:wait?ds24Badge('Đang chờ','Neutral'):'',leading:null,type:'Navigation',attrs:`data-v313-val13-task="${t.id}"`});}).join('');
    const body=`${ds24Search(val13Query,'data-val13-search','Nguồn điều chỉnh hoặc đối tác')}<div class="ds24-chip-scroll">${ds24Chip('ALL','Tất cả',v313Val13Filter==='ALL','data-v313-val13-filter')}${ds24Chip('ACTIONABLE','Có thể xử lý',v313Val13Filter==='ACTIONABLE','data-v313-val13-filter')}${ds24Chip('WAITING','Đang chờ',v313Val13Filter==='WAITING','data-v313-val13-filter')}</div>${rows?`<section class="ds24-list-stack v313-list">${rows}</section>`:ioEmpty('Không có công việc phù hợp','Đổi từ khóa hoặc bộ lọc để xem công việc khác.')}`;
    return appShell({title:'Điều chỉnh giá trị hàng nhập',body,back:false});
  }
  function render086V313(state){
    if(activeFlowId!=='UIF-13')return renderGeneric(screens.find(s=>s.id==='SCR-086'),state);const t=val13Current();
    if(state==='LOADING')return appShell({title:'Nguồn, phạm vi và phân bổ',body:loadingBody(),centered:true});
    if(state==='PERMISSION_DENIED')return appShell({title:'Nguồn, phạm vi và phân bổ',body:deniedBody(),centered:true});
    if(t.status==='WAITING')return appShell({title:'Nguồn, phạm vi và phân bổ',body:`${vBanner('info','Chưa thể xử lý',t.waitingOwner||'Đang chờ căn cứ cần thiết.')}${v313Val13Source(t)}${(t.targets||[]).length?`${heading('Phạm vi liên quan')}${v313Val13Targets(t)}`:''}`});
    const changed=state==='SOURCE_CHANGED'||Boolean(val13LastSourceChange);
    const body=`${changed?vBanner('warning','Nguồn điều chỉnh đã thay đổi','Preview cũ không còn hiệu lực. Kiểm tra lại phạm vi và cách phân bổ.'):''}${v313Val13Source(t)}${heading('Phạm vi áp dụng',t.targetScopeMode==='FIXED'?'Theo nguồn xác định':'Chọn trong phạm vi cho phép')}<section class="ds24-list-stack v313-list">${v313Val13Targets(t)}</section>${v313Val13Method(t)}${v313Val13Preview(t)}${info('Kỳ ghi nhận',ds24InfoRow('Kỳ gốc',t.originalPeriod||'—')+ds24InfoRow('Kỳ ghi nhận',t.postingPeriod||'—')+(t.periodReason?ds24InfoRow('Lý do',t.periodReason):''))}`;
    return appShell({title:'Nguồn, phạm vi và phân bổ',body,actions:primaryFooter('Rà soát điều chỉnh','data-v313-val13-review',!val13CanPreview(t))});
  }
  function render087V313(state){return render086V313(state);}
  function render088V313(state){
    if(activeFlowId!=='UIF-13')return renderGeneric(screens.find(s=>s.id==='SCR-088'),state);const t=val13Current();
    if(state==='PERMISSION_DENIED')return appShell({title:'Rà soát điều chỉnh giá trị',body:deniedBody(),centered:true});
    const stale=state==='SOURCE_CHANGED'||val13PreviewHash==null||val13PreviewHash!==val13PreviewHashOf(t)||Number(val13ReviewSourceVersion)!==Number(t.sourceVersion);
    if(stale)return appShell({title:'Rà soát điều chỉnh giá trị',body:`${vBanner('warning','Nguồn hoặc phân bổ đã thay đổi','Tạo lại preview trước khi ghi điều chỉnh.')}${v313Val13Source(t)}`,actions:primaryFooter('Tạo lại preview','data-v313-val13-back')});
    const p=val13Preview(t),rows=p.map(x=>key(`${x.product} · ${x.receipt}`,signed(x.allocatedAmount))).join('');
    const body=`${v313Val13Source(t)}${info('Cách phân bổ',ds24InfoRow('Phương pháp',(t.allowedMethods||[]).find(m=>m.id===t.selectedMethod)?.label||'—')+ds24InfoRow('Kỳ gốc',t.originalPeriod||'—')+ds24InfoRow('Kỳ ghi nhận',t.postingPeriod||'—'))}${heading('Phân bổ sẽ ghi')}<div class="v313-kv">${rows}${key('Tổng điều chỉnh',signed(t.normalizedAmount),true)}</div>${vBanner('info','Sau khi ghi','Số lượng tồn không đổi. Các sản phẩm liên quan sẽ được đánh dấu cần cập nhật giá vốn.','','Compact')}${linkButton('Chỉnh sửa phân bổ','data-v313-val13-back')}`;
    return appShell({title:'Rà soát điều chỉnh giá trị',body,actions:primaryFooter('Ghi điều chỉnh','data-v313-val13-confirm')});
  }
  function render089V313(state){
    if(activeFlowId!=='UIF-13')return renderGeneric(screens.find(s=>s.id==='SCR-089'),state);const res=val13Result();
    if(state==='PROCESSING')return appShell({title:'Kết quả điều chỉnh giá trị',body:loadingBody(),centered:true,back:false});
    if(state==='UNKNOWN'){const attrs=`data-v350-action="handoff-unknown" data-source-flow="UIF-13" data-operation="${escapeAttribute(res.operationId||'ADJ-UNKNOWN')}" data-scope="${escapeAttribute(res.sourceRef||'')}"`;return appShell({title:'Đang xác minh kết quả',body:ioResult('Chưa xác định điều chỉnh đã được ghi hay chưa','Không gửi lại lệnh. Chuyển đúng lần xử lý này sang xác minh kết quả.',[['Nguồn',res.sourceRef],['Trạng thái','Đang xác minh']],'warning'),centered:true,back:false,actions:primaryFooter('Chuyển sang xác minh',attrs)});}
    if(state==='REJECTED_EXECUTION')return appShell({title:'Kết quả điều chỉnh giá trị',body:ioResult('Chưa ghi điều chỉnh giá trị','Không có thay đổi. Kiểm tra lại nguồn và phân bổ hiện hành.',[['Nguồn',res.sourceRef],['Tác động','Không thay đổi']],'warning'),centered:true,back:false,actions:primaryFooter('Xem lại phân bổ','data-v313-val13-back')});
    const rows=(res.allocations||[]).map(x=>key(`${x.product} · ${x.receipt}`,signed(x.allocatedAmount))).join('');
    const body=`<div class="io-result">${resultHero(Number(res.normalizedAmount||0)<0?'Đã ghi giảm giá trị hàng nhập':'Đã ghi điều chỉnh giá trị hàng nhập','Điều chỉnh đã được ghi theo phạm vi và kỳ đã rà soát.')}${info('Kết quả',ds24InfoRow('Nguồn',res.sourceRef)+key('Tổng điều chỉnh',signed(res.normalizedAmount),true)+ds24InfoRow('Kỳ ghi nhận',res.postingPeriod||'—')+ds24InfoRow('Giá vốn','Cần cập nhật'))}${rows?`<div class="v313-kv">${rows}</div>`:''}</div>`;
    return appShell({title:'Kết quả điều chỉnh giá trị',body,centered:true,back:false,actions:primaryFooter('Về công việc điều chỉnh','data-v313-val13-list')});
  }

  // ---------------------------------------------------------------------------
  // BJ14 — Tính, rà soát và công bố giá vốn
  // ---------------------------------------------------------------------------
  let v313Val14Mode='RESULT';
  let v313Val14PublishSheet=false;
  let v313Val14CompareOpen=false;
  function v313EnrichRun(r){try{window.__VET45_V399__?.enrichRun?.(r,0);}catch(_){}r.policyMethod='PERIODIC';r.policyLabel='Bình quân cuối kỳ';r.policyVersion='Chính sách giá vốn';return r;}
  if(typeof val14Runs!=='undefined')val14Runs.forEach(v313EnrichRun);
  function v313RunScope(r){return r.scopeOrigin==='DIRTY_SCOPE'?`${r.productCount||3} sản phẩm cần cập nhật`:r.scope;}
  function v313Val14WorkMeta(r){
    v313EnrichRun(r);
    if(r.status==='DIRTY')return {title:'Cập nhật giá vốn',subtitle:`${r.productCount||3} sản phẩm · có thay đổi giá trị`,label:'Cần tính lại',tone:'Warning'};
    if(r.status==='READY_FOR_REVIEW')return {title:`Chốt giá vốn ${r.period}`,subtitle:`Đã tính · ${r.productCount||r.scope} · chờ công bố`,label:'Sẵn sàng',tone:'Success'};
    if(r.status==='BLOCKED')return {title:`Chốt giá vốn ${r.period}`,subtitle:`${r.blockers?.length||0} vấn đề cần xử lý`,label:'Bị chặn',tone:'Warning'};
    return {title:r.label,subtitle:v313RunScope(r),label:'Đang xử lý',tone:'Neutral'};
  }
  function v313Policy(r){return info('Chính sách giá vốn',ds24InfoRow('Phương pháp áp dụng','Bình quân cuối kỳ')+ds24InfoRow('Cấp cấu hình','Tổ chức')+ds24InfoRow('Trạng thái','Áp dụng tự động'));}
  function v313Blockers(r){return (r.blockers||[]).map(b=>readiness(b.title,`Đang chờ: ${b.owner}`,'Warning')).join('');}
  function v313PrimaryResult(r){v313EnrichRun(r);const x=r.periodic||{};return `${summary('Kết quả theo phương pháp áp dụng',`Bình quân cuối kỳ · ${v313RunScope(r)}`,'Brand')}<div class="v313-kv">${key('Giá trị tồn cuối',val14Money(x.inventory||0),true)}${key('Giá vốn xuất',val14Money(x.cogs||0),true)}${key('Điều chỉnh giá vốn xuất',signed(r.cogsTrueUp||0))}${key('Điều chỉnh giá trị tồn',signed(r.endingAdjustment||0))}</div>`;}
  function v313Compare(r){const x=r.moving||{};return `<details class="v313-details" ${v313Val14CompareOpen?'open':''} data-v313-compare><summary>Xem đối chiếu</summary><div class="v313-details__body">${info('Bình quân liên hoàn · chỉ đối chiếu',key('Giá trị tồn cuối',val14Money(x.inventory||0))+key('Giá vốn xuất',val14Money(x.cogs||0)))}</div></details>`;}
  function v313PeriodSetup(r){
    const isDirty=v313Val14Mode==='DIRTY_SETUP';
    const period=isDirty?(r?.period||val14SetupPeriod):val14SetupPeriod;
    const scope=isDirty?v313RunScope(r):val14SetupScope;
    const controls=isDirty?info('Phạm vi cần cập nhật',ds24InfoRow('Kỳ ghi nhận',period)+ds24InfoRow('Phạm vi',scope)+ds24InfoRow('Nguồn phạm vi','Hệ thống xác định từ thay đổi giá trị')):`${field('Kỳ',select('data-val14-period',`<option ${val14SetupPeriod==='08/2026'?'selected':''}>08/2026</option><option ${val14SetupPeriod==='09/2026'?'selected':''}>09/2026</option>`))}${field('Phạm vi',select('data-val14-scope',`<option ${val14SetupScope==='Toàn bộ sản phẩm'?'selected':''}>Toàn bộ sản phẩm</option><option ${val14SetupScope==='Sản phẩm cần tính lại'?'selected':''}>Sản phẩm cần tính lại</option>`))}`;
    return `${controls}${v313Policy(r||{})}`;
  }
  function v313PublishSheet(r){
    const content=`${vBanner('info','Công bố kết quả đã rà soát','Hệ thống chỉ ghi phần chênh lệch và phiên bản giá vốn mới; không sửa chứng từ lịch sử.','','Compact')}${info('Phạm vi công bố',ds24InfoRow('Kỳ ghi nhận',r.postingPeriod||r.period)+ds24InfoRow('Phạm vi',v313RunScope(r))+ds24InfoRow('Phương pháp','Bình quân cuối kỳ'))}${info('Chênh lệch sẽ ghi',key('Giá vốn xuất',signed(r.cogsTrueUp||0),true)+key('Giá trị tồn cuối',signed(r.endingAdjustment||0),true))}`;
    return sheet('Công bố giá vốn',content,`${button('Hủy','data-v313-val14-publish-sheet="close"','secondary')}${button('Công bố','data-v313-val14-publish')}`);
  }
  function render072V313(state){
    if(activeFlowId!=='UIF-14')return renderGeneric(screens.find(s=>s.id==='SCR-072'),state);
    if(state==='LOADING')return appShell({title:'Công việc giá vốn',body:loadingBody(),centered:true,back:false});
    if(state==='PERMISSION_DENIED')return appShell({title:'Công việc giá vốn',body:deniedBody(),centered:true,back:false});
    const active=val14Runs.filter(r=>r.status!=='PUBLISHED');
    const rows=active.map(r=>{const m=v313Val14WorkMeta(r);return row({title:m.title,subtitle:m.subtitle,trailing:ds24Badge(m.label,m.tone),leading:null,type:'Navigation',attrs:`data-v313-val14-run="${r.id}"`});}).join('');
    const body=`${rows?`<section class="ds24-list-stack v313-list">${rows}</section>`:ioEmpty('Không có công việc giá vốn','Chưa có phạm vi cần cập nhật hoặc chốt kỳ.')}`;
    return appShell({title:'Công việc giá vốn',body,back:false,actions:primaryFooter('Chốt kỳ','data-v313-val14-close-period')});
  }
  function render074V313(state){
    if(activeFlowId!=='UIF-14')return renderGeneric(screens.find(s=>s.id==='SCR-074'),state);const r=v313EnrichRun(val14Current());
    if(state==='PERMISSION_DENIED')return appShell({title:'Tính và rà soát giá vốn',body:deniedBody(),centered:true});
    if(state==='INPUT_CHANGED'||r.status==='INPUT_CHANGED')return appShell({title:'Tính và rà soát giá vốn',body:`${vBanner('warning','Dữ liệu đầu vào đã thay đổi','Kết quả cũ được giữ để truy vết nhưng không còn đủ điều kiện công bố.')}${v313Policy(r)}`,actions:primaryFooter('Tạo lần tính kế tiếp','data-v313-val14-successor')});
    if(v313Val14Mode==='DIRTY_SETUP'||v313Val14Mode==='PERIOD_CLOSE_SETUP')return appShell({title:v313Val14Mode==='DIRTY_SETUP'?'Cập nhật giá vốn':'Chốt giá vốn kỳ',body:`${v313PeriodSetup(r)}`,actions:primaryFooter(v313Val14Mode==='DIRTY_SETUP'?'Tính lại giá vốn':'Tính giá vốn','data-v313-val14-calculate')});
    if(r.status==='CALCULATING'||state==='PROCESSING')return appShell({title:'Tính và rà soát giá vốn',body:ioResult('Đang tính giá vốn','Có thể rời màn hình. Kết quả được lưu trong cùng lần tính.',[['Kỳ ghi nhận',r.postingPeriod||r.period],['Phạm vi',v313RunScope(r)]],'info'),centered:true});
    if(r.status==='BLOCKED'||state==='BLOCKED')return appShell({title:'Tính và rà soát giá vốn',body:`${vBanner('warning','Chưa thể chốt giá vốn','Xử lý các vấn đề dưới đây; hệ thống sẽ giữ nguyên phạm vi công việc này.')}${v313Policy(r)}${heading('Cần xử lý',`${r.blockers?.length||0} vấn đề`)}<div class="v313-readiness-list">${v313Blockers(r)}</div>`});
    const productRows=(r.productResults||[]).slice(0,6).map(x=>row({title:x.product||x.name||'Sản phẩm',subtitle:x.state==='NO_NEW_COST_BASIS'?'Chưa có căn cứ giá vốn mới':`Giá vốn mới ${x.newCost!=null?money(x.newCost):'—'}`,trailing:x.state==='NO_NEW_COST_BASIS'?ds24Badge('Không đổi','Neutral'):'',leading:null,type:'Status',interactive:false})).join('');
    const body=`${v313Policy(r)}${v313PrimaryResult(r)}${v313Compare(r)}${productRows?`${heading('Kết quả theo sản phẩm',`${r.changedProductCount||0} có thay đổi`)}<section class="ds24-list-stack v313-list">${productRows}</section>`:''}${v313Val14PublishSheet? v313PublishSheet(r):''}`;
    return appShell({title:'Tính và rà soát giá vốn',body,actions:primaryFooter('Công bố giá vốn','data-v313-val14-open-publish',r.status!=='READY_FOR_REVIEW')});
  }
  function render073V313(){v313Val14Mode='PERIOD_CLOSE_SETUP';return render074V313('READY');}
  function render075V313(state){return render074V313(state);}
  function render076V313(state){v313Val14PublishSheet=true;return render074V313(state);}
  function render077V313(state){
    if(activeFlowId!=='UIF-14')return renderGeneric(screens.find(s=>s.id==='SCR-077'),state);const r=v313EnrichRun(val14Current());const res=val14LastResult||{runId:r.id,postingPeriod:r.postingPeriod||r.period,method:'Bình quân cuối kỳ',reconciledProducts:r.productCount||0,officialCostVersions:0,effectiveAt:r.effectiveAt,cogsTrueUp:r.cogsTrueUp,endingAdjustment:r.endingAdjustment};
    if(state==='PROCESSING')return appShell({title:'Kết quả công bố giá vốn',body:loadingBody(),centered:true,back:false});
    if(state==='UNKNOWN'){const attrs=`data-v350-action="handoff-unknown" data-source-flow="UIF-14" data-operation="${escapeAttribute(res.runId||r.id)}" data-scope="${escapeAttribute(res.postingPeriod||r.period)}"`;return appShell({title:'Đang xác minh kết quả',body:ioResult('Chưa xác định giá vốn đã được công bố hay chưa','Không gửi lại lệnh công bố. Chuyển đúng lần này sang xác minh kết quả.',[['Lần tính',res.runId||r.id],['Trạng thái','Đang xác minh']],'warning'),centered:true,back:false,actions:primaryFooter('Chuyển sang xác minh',attrs)});}
    const body=`<div class="io-result">${resultHero('Đã công bố giá vốn','Kết quả đã được ghi và có hiệu lực theo kỳ, phạm vi đã rà soát.')}${info('Kết quả',ds24InfoRow('Kỳ ghi nhận',res.postingPeriod||r.period)+ds24InfoRow('Phương pháp','Bình quân cuối kỳ')+ds24InfoRow('Sản phẩm đã đối soát',String(res.reconciledProducts||r.productCount||0))+ds24InfoRow('Hiệu lực',res.effectiveAt||r.effectiveAt)+key('Giá vốn xuất',signed(res.cogsTrueUp||0),true)+key('Giá trị tồn cuối',signed(res.endingAdjustment||0),true))}</div>`;
    return appShell({title:'Kết quả công bố giá vốn',body,centered:true,back:false,actions:primaryFooter('Về công việc giá vốn','data-v313-val14-list')});
  }

  // Renderer rebinding — last loaded layer owns valuation cluster only.
  Object.assign(renderers,{
    'SCR-014':render014V313,'SCR-015':render015V313,'SCR-016':render016V313,'SCR-017':render017V313,'SCR-019':render019V313,
    'SCR-085':render085V313,'SCR-086':render086V313,'SCR-087':render087V313,'SCR-088':render088V313,'SCR-089':render089V313,
    'SCR-072':render072V313,'SCR-073':render073V313,'SCR-074':render074V313,'SCR-075':render075V313,'SCR-076':render076V313,'SCR-077':render077V313
  });

  // Capture custom actions before legacy document-level handlers.
  window.addEventListener('click',(event)=>{
    let el;
    if(activeFlowId==='UIF-03'){
      if((el=event.target.closest('[data-v313-val03-filter]'))){event.preventDefault();event.stopImmediatePropagation();v313Val03Filter=el.dataset.v313Val03Filter;return renderAppScreen();}
      if((el=event.target.closest('[data-v313-val03-receipt]'))){event.preventDefault();event.stopImmediatePropagation();val03SelectedReceiptId=el.dataset.v313Val03Receipt;v313Val03ClearSelection();v313Val03Sheet=null;stateByScreen['SCR-015']='READY';return navigate('SCR-015');}
      if((el=event.target.closest('[data-v313-val03-select]'))){event.preventDefault();event.stopImmediatePropagation();const g=val03Current().groups.find(x=>x.id===el.dataset.v313Val03Select);if(g&&v313Val03GroupState(val03Current(),g)==='READY')v313Val03SelectGroup(g,!v313Val03SelectedGroups().includes(g));return renderAppScreen();}
      if((el=event.target.closest('[data-v313-val03-add-basis]'))){event.preventDefault();event.stopImmediatePropagation();v313Val03Sheet=el.dataset.v313Val03AddBasis;return renderAppScreen();}
      if((el=event.target.closest('[data-v313-tax-mode]'))){event.preventDefault();event.stopImmediatePropagation();document.querySelectorAll('[data-v313-tax-mode]').forEach(x=>x.classList.toggle('is-selected',x===el));const wrap=document.querySelector('[data-v313-tax-amount-wrap]');if(wrap)wrap.hidden=el.dataset.v313TaxMode!=='EXCLUDED';return;}
      if((el=event.target.closest('[data-v313-val03-sheet]'))){event.preventDefault();event.stopImmediatePropagation();if(el.dataset.v313Val03Sheet==='close'){v313Val03Sheet=null;return renderAppScreen();}if(el.dataset.v313Val03Sheet==='save'&&v313Val03SaveBasis(v313Val03Sheet)){v313Val03Sheet=null;return renderAppScreen();}return;}
      if(event.target.closest('[data-v313-sheet-backdrop]')&&!event.target.closest('.v313-sheet')){event.preventDefault();event.stopImmediatePropagation();v313Val03Sheet=null;return renderAppScreen();}
      if((el=event.target.closest('[data-v313-val03-review]'))){event.preventDefault();event.stopImmediatePropagation();if(!v313Val03CanReview())return;val03ReviewSourceVersion=val03Current().sourceVersion;stateByScreen['SCR-017']='READY';return navigate('SCR-017');}
      if((el=event.target.closest('[data-v313-val03-back]'))){event.preventDefault();event.stopImmediatePropagation();stateByScreen['SCR-015']='READY';return navigate('SCR-015');}
      if((el=event.target.closest('[data-v313-val03-confirm]'))){event.preventDefault();event.stopImmediatePropagation();if(Number(val03ReviewSourceVersion)!==Number(val03Current().sourceVersion)){stateByScreen['SCR-017']='SOURCE_CHANGED';return renderAppScreen();}v313Val03Commit();stateByScreen['SCR-019']='COMPLETED';return navigate('SCR-019');}
      if((el=event.target.closest('[data-v313-val03-result-back]'))){event.preventDefault();event.stopImmediatePropagation();v313Val03ClearSelection();stateByScreen['SCR-015']='READY';return navigate('SCR-015');}
      if((el=event.target.closest('[data-v313-val03-result-list]'))){event.preventDefault();event.stopImmediatePropagation();val03Query='';v313Val03Filter='ALL';return navigate('SCR-014');}
    }
    if(activeFlowId==='UIF-13'){
      if((el=event.target.closest('[data-v313-val13-filter]'))){event.preventDefault();event.stopImmediatePropagation();v313Val13Filter=el.dataset.v313Val13Filter;return renderAppScreen();}
      if((el=event.target.closest('[data-v313-val13-task]'))){event.preventDefault();event.stopImmediatePropagation();val13SelectedTaskId=el.dataset.v313Val13Task;val13ResetTaskDraft(val13Current());stateByScreen['SCR-086']='READY';return navigate('SCR-086');}
      if((el=event.target.closest('[data-v313-val13-review]'))){event.preventDefault();event.stopImmediatePropagation();const t=val13Current();if(!val13CanPreview(t)){stateByScreen['SCR-086']='VALIDATION_ERROR';return renderAppScreen();}val13ReviewSourceVersion=t.sourceVersion;val13PreviewHash=val13PreviewHashOf(t);stateByScreen['SCR-088']='READY';return navigate('SCR-088');}
      if((el=event.target.closest('[data-v313-val13-back]'))){event.preventDefault();event.stopImmediatePropagation();stateByScreen['SCR-086']='READY';return navigate('SCR-086');}
      if((el=event.target.closest('[data-v313-val13-confirm]'))){event.preventDefault();event.stopImmediatePropagation();const t=val13Current();if(Number(val13ReviewSourceVersion)!==Number(t.sourceVersion)||val13PreviewHash!==val13PreviewHashOf(t)){stateByScreen['SCR-088']='SOURCE_CHANGED';return renderAppScreen();}val13Commit();stateByScreen['SCR-089']='COMPLETED';return navigate('SCR-089');}
      if((el=event.target.closest('[data-v313-val13-list]'))){event.preventDefault();event.stopImmediatePropagation();val13Query='';v313Val13Filter='ALL';return navigate('SCR-085');}
    }
    if(activeFlowId==='UIF-14'){
      if((el=event.target.closest('[data-v313-val14-run]'))){event.preventDefault();event.stopImmediatePropagation();val14SelectedRunId=el.dataset.v313Val14Run;const r=v313EnrichRun(val14Current());v313Val14PublishSheet=false;v313Val14CompareOpen=false;if(r.status==='DIRTY'){val14SetupKind='AD_HOC';val14SetupPeriod=r.period;val14SetupScope='Sản phẩm cần tính lại';val14SuccessorOf=r.id;v313Val14Mode='DIRTY_SETUP';}else{v313Val14Mode='RESULT';stateByScreen['SCR-074']=r.status==='BLOCKED'?'BLOCKED':'READY';}return navigate('SCR-074');}
      if((el=event.target.closest('[data-v313-val14-close-period]'))){event.preventDefault();event.stopImmediatePropagation();val14SuccessorOf=null;val14SetupKind='PERIOD_CLOSE';val14SetupScope='Toàn bộ sản phẩm';v313Val14Mode='PERIOD_CLOSE_SETUP';return navigate('SCR-074');}
      if((el=event.target.closest('[data-v313-val14-calculate]'))){event.preventDefault();event.stopImmediatePropagation();val14SetupKind=v313Val14Mode==='DIRTY_SETUP'?'AD_HOC':'PERIOD_CLOSE';const run=val14CreateRun();v313EnrichRun(run);v313Val14Mode='RESULT';stateByScreen['SCR-074']='READY';return renderAppScreen();}
      if((el=event.target.closest('[data-v313-val14-open-publish]'))){event.preventDefault();event.stopImmediatePropagation();const r=v313EnrichRun(val14Current());if(r.status!=='READY_FOR_REVIEW')return;val14PublishReviewVersion=r.runInputHash||String(r.inputVersion);v313Val14PublishSheet=true;return renderAppScreen();}
      if((el=event.target.closest('[data-v313-val14-publish-sheet]'))){event.preventDefault();event.stopImmediatePropagation();v313Val14PublishSheet=false;return renderAppScreen();}
      if((el=event.target.closest('[data-v313-val14-publish]'))){event.preventDefault();event.stopImmediatePropagation();const r=v313EnrichRun(val14Current());if(String(val14PublishReviewVersion)!==String(r.runInputHash||r.inputVersion)){r.status='INPUT_CHANGED';v313Val14PublishSheet=false;stateByScreen['SCR-074']='INPUT_CHANGED';return renderAppScreen();}val14Commit();v313Val14PublishSheet=false;stateByScreen['SCR-077']='COMPLETED';return navigate('SCR-077');}
      if((el=event.target.closest('[data-v313-val14-successor]'))){event.preventDefault();event.stopImmediatePropagation();const r=val14Current();val14SuccessorOf=r.id;val14SetupKind=r.kind;val14SetupPeriod=r.period;val14SetupScope=r.scopeOrigin==='DIRTY_SCOPE'?'Sản phẩm cần tính lại':'Toàn bộ sản phẩm';v313Val14Mode=r.scopeOrigin==='DIRTY_SCOPE'?'DIRTY_SETUP':'PERIOD_CLOSE_SETUP';return renderAppScreen();}
      if((el=event.target.closest('[data-v313-val14-list]'))){event.preventDefault();event.stopImmediatePropagation();v313Val14Mode='RESULT';v313Val14PublishSheet=false;return navigate('SCR-072');}
    }
  },true);

  if(window.__VET45_PROTOTYPE__) window.__VET45_PROTOTYPE__.version='3.13.0';
  window.__VET45_V313__={version:'3.13.0',screens:{bj03:['SCR-014','SCR-015','SCR-017','SCR-019'],bj13:['SCR-085','SCR-086','SCR-088','SCR-089'],bj14:['SCR-072','SCR-074','SCR-077']}};
})();
