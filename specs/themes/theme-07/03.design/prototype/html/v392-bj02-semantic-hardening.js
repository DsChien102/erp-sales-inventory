/* v3.9.2 — Wave 2 / BJ02 deep-review semantic hardening.
 * Authority: approved BJ02 Decision Pack D01..D11.
 * This layer runs after v3.9.0 orchestration so current renderers are wrapped, not forked.
 */
(() => {
  const V392 = window.VET45_BJ02_V392 = {
    version: '3.9.2',
    warehouse: { id: 'WH-CENTRAL', name: 'Kho trung tâm' },
    tenantBusinessDate: typeof BJ02_TENANT_BUSINESS_DATE !== 'undefined' ? BJ02_TENANT_BUSINESS_DATE : '2026-09-16',
    capabilities: {
      quickReceipt: true,
      assertOwnership: true,
      viewApprovalRiskTotal: true,
    },
    quickBlocker: null,
    submitted: {
      maker: 'Nguyễn Văn An',
      submittedAt: '16/09/2026 · 09:41',
      receiptRef: 'REC-260916-04',
    },
    recoveryEvidence: {
      checkedAt: '16/09/2026 · 09:45:18',
      submitted: { proven: true, at: '16/09/2026 · 09:41:06', actor: 'Nguyễn Văn An' },
      approval: { proven: true, at: '16/09/2026 · 09:43:22', actor: 'Trần Minh Hòa' },
      operationResult: { proven: true, at: '16/09/2026 · 09:45:02' },
      inventoryMovement: { proven: true, at: '16/09/2026 · 09:45:03', ledgerSequence: 281044 },
    },
    evidenceSheetOpen: false,
    changeSourceConfirmOpen: false,
  };

  function v392Esc(v){ return typeof esc === 'function' ? esc(v) : String(v ?? ''); }
  function v392DateText(iso){ return typeof formatIsoDate === 'function' ? formatIsoDate(iso) : iso; }
  function v392AcceptedPhysical(line){ return lineTotals(line).physicalIncrease; }
  function v392AcceptedPhysicalTotal(){ return bj02Lines.reduce((n,line)=>n+v392AcceptedPhysical(line),0); }
  function v392InspectedTotal(){ return bj02Lines.reduce((n,line)=>n+lineTotals(line).totalReceived,0); }
  function v392RejectedTotal(){ return bj02Lines.reduce((n,line)=>n+lineTotals(line).rejected,0); }
  function v392HasPriceBasis(){
    return bj02Lines.every((line)=>{
      if(line?.status === 'NOT_RECEIVED') return true;
      const basis=line.priceBasisSnapshot || productById(line.productId)?.priceBasisSnapshot;
      return Boolean(basis && Number(basis.unitPriceVndPerBase)>0 && basis.priceVersion && basis.fxVersion);
    });
  }
  function v392SourceRemaining(line){ return Math.max(0,Number(line?.remainingReceivableQty)||0); }
  function v392FormatDateWithPrecision(value,precision='DAY'){
    const v=String(value||'').trim();
    if(!v) return '';
    if(precision==='YEAR') return v.replace(/\D/g,'').slice(-4) || v;
    if(precision==='MONTH'){
      const m=v.match(/^(\d{1,2})[\/\-](\d{4})$/); return m?`${m[1].padStart(2,'0')}/${m[2]}`:v;
    }
    return v;
  }
  function v392ValidPrecisionValue(value,precision='DAY'){
    const v=String(value||'').trim();
    if(!v) return false;
    if(precision==='YEAR') return /^\d{4}$/.test(v);
    if(precision==='MONTH') return /^(0?[1-9]|1[0-2])[\/\-]\d{4}$/.test(v);
    return /^(0?[1-9]|[12]\d|3[01])[\/\-](0?[1-9]|1[0-2])[\/\-]\d{4}$/.test(v);
  }
  function v392EvidenceRefs(){
    const refs=Array.isArray(bj02Header.evidenceRefs)?bj02Header.evidenceRefs:[];
    if(refs.length) return refs;
    return bj02Header.evidence ? [{id:'EV-LEGACY-1',name:bj02Header.evidence,type:'DELIVERY_DOCUMENT'}] : [];
  }
  function v392EvidenceLabel(){
    const refs=v392EvidenceRefs();
    if(!refs.length) return 'Chưa có';
    if(refs.length===1) return refs[0].name;
    return `${refs.length} tệp chứng từ`;
  }
  function v392OwnershipReady(){ return Boolean(bj02Header.ownershipAssertion?.status==='ASSERTED'); }
  function v392MakeOwnershipAssertion(){
    bj02Header.ownershipAssertion={
      status:'ASSERTED',
      actorId:'USR-NVA',
      actorName:'Nguyễn Văn An',
      assertedAt:'2026-09-16T10:34:00+07:00',
      evidenceRefs:v392EvidenceRefs().map((x)=>x.id),
      assertionVersion:'OWN-v1',
    };
  }

  // Ensure every live document line carries source authority + conversion + price basis snapshot.
  Object.values(documentReceiptCatalog).forEach((doc)=>{
    doc.documentDate ||= doc.businessDate || '16/08/2026';
    doc.sourceDocumentVersion ||= 'v1';
    (doc.lines||[]).forEach((line)=>{
      const product=productById(line.productId);
      const uom=product?.uoms?.find((x)=>x.id===line.uomId);
      line.sourceLineVersion ||= 'v1';
      line.conversionRatioSnapshot ||= uom?.conversionRatio || 1;
      line.priceBasisSnapshot ||= product?.priceBasisSnapshot ? cloneBj02(product.priceBasisSnapshot) : null;
    });
  });
  bj02Header.businessDate=V392.tenantBusinessDate;
  bj02Header.evidenceRefs ||= [];
  if('note' in bj02Header) delete bj02Header.note;

  // Canonical line helpers for D01/D02/D05.
  documentLineVariance = function(line){
    if(flowMode!=='document'||!line||line.remainingReceivableQty==null) return null;
    const t=lineTotals(line), allowed=v392SourceRemaining(line);
    return {
      allowed,
      totalInspected:t.totalReceived,
      acceptedPhysical:t.physicalIncrease,
      rejected:t.rejected,
      remainingAfterAccepted:Math.max(0,allowed-t.physicalIncrease),
      inspectedOver:Math.max(0,t.totalReceived-allowed),
      acceptedPhysicalOver:Math.max(0,t.physicalIncrease-allowed),
    };
  };
  documentVarianceFeedback = function(line){
    const v=documentLineVariance(line); if(!v||v.totalInspected<=0) return '';
    if(v.acceptedPhysicalOver>0) return vBanner('warning','Lượng vào tồn vượt chứng từ',`Vào tồn vật lý ${v.acceptedPhysical} ${line.uom}, vượt ${v.acceptedPhysicalOver} ${line.uom} so với lượng còn được nhận. Hồ sơ sẽ cần phê duyệt.`,'','Compact');
    if(v.acceptedPhysical<v.allowed) return vBanner('info','Còn hàng chưa nhận',`Vào tồn vật lý ${v.acceptedPhysical} ${line.uom}; còn ${v.remainingAfterAccepted} ${line.uom} theo chứng từ nguồn.`,'','Compact');
    if(v.inspectedOver>0) return vBanner('info','Có lượng từ chối ngoài số vào tồn',`Tổng kiểm nhận ${v.totalInspected} ${line.uom}; vào tồn vật lý ${v.acceptedPhysical} ${line.uom}. Lượng từ chối không làm tăng tồn.`,'','Compact');
    return '';
  };
  lineAcceptedBase = function(line){
    const product=productById(line.productId); const uom=product?.uoms?.find((x)=>x.id===line.uomId);
    const ratio=Number(line.conversionRatioSnapshot ?? uom?.conversionRatio ?? 1)||1;
    return v392AcceptedPhysical(line)*ratio;
  };
  documentLineAllowanceBase = function(line){
    const product=productById(line.productId); const uom=product?.uoms?.find((x)=>x.id===line.uomId);
    const ratio=Number(line.conversionRatioSnapshot ?? uom?.conversionRatio ?? 1)||1;
    return v392SourceRemaining(line)*ratio;
  };
  bj02RequiresApproval = function(){
    if(flowMode==='quick') return true;
    return bj02Lines.some((line)=>lineAcceptedBase(line)>documentLineAllowanceBase(line));
  };
  receiptRiskValue = function(){
    return bj02Lines.reduce((sum,line)=>{
      const basis=line.priceBasisSnapshot || productById(line.productId)?.priceBasisSnapshot;
      return sum + lineAcceptedBase(line)*(Number(basis?.unitPriceVndPerBase)||0);
    },0);
  };
  bj02ReviewIssue = function(line){
    const t=lineTotals(line);
    if(line?.status==='NOT_RECEIVED') return {label:'Chưa nhận',tone:'warning'};
    if(line?.status!=='COMPLETED') return {label:'Chưa xong',tone:'warning'};
    if(t.rejected>0) return {label:'Có từ chối',tone:'error'};
    if(t.damaged>0) return {label:'Có hàng hỏng',tone:'error'};
    if(t.quarantine>0) return {label:'Có cách ly',tone:'warning'};
    if(flowMode==='document'&&line.remainingReceivableQty!=null&&t.physicalIncrease>v392SourceRemaining(line)) return {label:'Vượt chứng từ',tone:'warning'};
    if(flowMode==='document'&&line.remainingReceivableQty!=null&&t.physicalIncrease<v392SourceRemaining(line)) return {label:'Nhận một phần',tone:'info'};
    return null;
  };

  // Supplier selection: only name + code; changing supplier invalidates dependent assertions/evidence.
  bj02SupplierSelectSheet = function(locked=false){
    if(!supplierMenuOpen||locked) return '';
    const options=supplierCatalog.map((supplier)=>{
      const selected=supplier.id===bj02Header.supplierId;
      return `<button class="bj02-sheet-list-row${selected?' is-selected':''}" data-bj02-supplier-option="${supplier.id}" data-bj02-supplier-search-text="${escapeAttribute(`${supplier.name} ${supplier.code}`.toLowerCase())}" data-ds-component="DS v2 / List Row" data-figma-node="525:519" data-ds-prop-type="Selection" data-ds-prop-density="Default" data-ds-prop-state="${selected?'Selected':'Default'}" type="button" role="option" aria-selected="${selected}"><span class="bj02-ds-list-leading">${icon('user','icon--sm')}</span><span class="bj02-ds-list-copy"><strong>${v392Esc(supplier.name)}</strong><span>${v392Esc(supplier.code)}</span></span><span class="bj02-radio-control" aria-hidden="true"></span></button>`;
    }).join('');
    return `<div class="bj02-select-backdrop" data-bj02-supplier-backdrop><section class="bj02-select-sheet" data-ds-component="DS v2 / Select Sheet" data-figma-node="550:1148" role="dialog" aria-modal="true" aria-label="Chọn nhà cung cấp"><div class="bj02-sheet-handle"></div><h2>Chọn nhà cung cấp</h2><div class="bj02-sheet-search" data-ds-component="VSearchBar" data-figma-node="522:7245"><span>${icon('search','icon--sm')}</span><input data-bj02-supplier-search value="${escapeAttribute(supplierSearchQuery)}" placeholder="Tìm tên hoặc mã nhà cung cấp" autocomplete="off" aria-label="Tìm nhà cung cấp" /></div><div class="bj02-sheet-list" data-bj02-supplier-menu role="listbox">${options}<div class="combobox-empty" data-bj02-supplier-empty hidden>Không có nhà cung cấp phù hợp. Nhà cung cấp phải được tạo trước ở Theme 3.</div></div></section></div>`;
  };
  const v392SelectSupplierBase=selectSupplier;
  selectSupplier=function(supplierId){
    const changed=bj02Header.supplierId && bj02Header.supplierId!==supplierId;
    if(changed){
      bj02Header.evidence=''; bj02Header.evidenceRefs=[]; bj02Header.ownershipAssertion=null;
      bj02Lines.forEach((line)=>{ line.priceBasisVerified=false; });
    }
    v392SelectSupplierBase(supplierId);
    if(changed) showToast('Đã đổi nhà cung cấp; cần kiểm tra lại chứng từ và quyền sở hữu.','info');
  };

  // Source/header rows keep document date separate from receipt business date.
  bj02ReceiptContext=function(){
    const handled=receiptHandledCount(), total=bj02Lines.length;
    const progress=total?`${handled}/${total} đã xử lý`:'Chưa có mặt hàng';
    if(flowMode==='quick') return `<section class="bj02-context-section" data-ds-component="VSection"><div class="bj02-section-heading"><strong>Thông tin lần nhận</strong><span>${progress}</span></div><div class="bj02-info-stack">${bj02InfoRow('Nhà cung cấp',currentReceiptSupplier())}${bj02InfoRow('Kho nhận',V392.warehouse.name)}${bj02InfoRow('Ngày nhận',v392DateText(bj02Header.businessDate))}</div></section>`;
    return `<section class="bj02-context-section" data-ds-component="VSection"><div class="bj02-section-heading"><strong>Thông tin lần nhận</strong><span>${progress}</span></div><div class="bj02-info-stack">${bj02InfoRow('Chứng từ',selectedDocumentId)}${bj02InfoRow('Nhà cung cấp',currentReceiptSupplier())}${bj02InfoRow('Kho nhận',V392.warehouse.name)}${bj02InfoRow('Ngày nhận',v392DateText(bj02Header.businessDate||V392.tenantBusinessDate))}</div></section>`;
  };
  bj02SourceRows=function(){
    if(flowMode==='quick'){
      const own=v392OwnershipReady()?'Đã xác nhận':'Chưa xác nhận';
      return `${bj02InfoRow('Nhà cung cấp',bj02Header.supplier||'—')}${bj02InfoRow('Kho nhận',V392.warehouse.name)}${bj02InfoRow('Ngày nhận',v392DateText(bj02Header.businessDate))}${bj02ReadOnlyDetail('Chứng từ giao nhận',v392EvidenceLabel())}${bj02InfoRow('Quyền sở hữu',own)}`;
    }
    const doc=documentContext();
    return `${bj02InfoRow('Chứng từ',selectedDocumentId)}${bj02InfoRow('Nhà cung cấp',doc.supplier)}${bj02InfoRow('Kho nhận',V392.warehouse.name)}${bj02InfoRow('Ngày chứng từ',doc.documentDate)}${bj02InfoRow('Ngày nhận',v392DateText(bj02Header.businessDate||V392.tenantBusinessDate))}`;
  };

  // Expiry/manufacture precision preservation (DAY/MONTH/YEAR).
  renderActiveLotEditor=function(lot,index,canRemove=false){
    const t=lotDraftTotals(lot), expiryRequired=Boolean(lineEditorDraft.expiryRequired), locked=lineEditorIsReadOnly(), disabled=locked?'disabled':'';
    lot.expiryPrecision ||= 'DAY'; lot.manufacturePrecision ||= 'DAY';
    const precisionOptions=(value)=>['DAY','MONTH','YEAR'].map((p)=>`<option value="${p}" ${p===value?'selected':''}>${p==='DAY'?'Ngày / tháng / năm':p==='MONTH'?'Tháng / năm':'Năm'}</option>`).join('');
    const expiryPlaceholder=lot.expiryPrecision==='MONTH'?'mm/yyyy':lot.expiryPrecision==='YEAR'?'yyyy':'dd/mm/yyyy';
    const manufacturePlaceholder=lot.manufacturePrecision==='MONTH'?'mm/yyyy':lot.manufacturePrecision==='YEAR'?'yyyy':'dd/mm/yyyy';
    return `<div class="active-lot-editor v392-lot-editor" data-ds-role="lot-editor-composition" data-composed-from="VTextField,VSelect,VButton"><div class="form-stack lot-fields-compact">
      <div class="form-field" data-ds-component="VTextField" data-figma-node="522:7186"><label>Mã lô <span class="required">*</span></label><span class="input-shell"><input data-bj02-lot-field="code" value="${escapeAttribute(lot.code)}" placeholder="Nhập mã trên bao bì" ${disabled}/></span></div>
      <div class="v392-date-precision"><div class="form-field" data-ds-component="VSelect" data-figma-node="522:7291"><label>Cách ghi hạn dùng</label><span class="bj02-native-select-shell"><select data-v392-lot-precision="expiryPrecision" ${disabled}>${precisionOptions(lot.expiryPrecision)}</select>${icon('chevronDown','icon--sm')}</span></div><div class="form-field" data-ds-component="VTextField" data-figma-node="522:7186"><label>Hạn dùng ${expiryRequired?'<span class="required">*</span>':''}</label><span class="input-shell bj02-date-shell"><span class="bj02-date-leading">${icon('calendar','icon--sm')}</span><input data-bj02-lot-field="expiry" value="${escapeAttribute(lot.expiry)}" placeholder="${expiryPlaceholder}" inputmode="numeric" ${disabled}/></span><small>Nhập đúng định dạng trên bao bì.</small></div></div>
      ${lotManufactureExpanded||lot.manufactureDate?`<div class="v392-date-precision"><div class="form-field" data-ds-component="VSelect" data-figma-node="522:7291"><label>Cách ghi ngày sản xuất</label><span class="bj02-native-select-shell"><select data-v392-lot-precision="manufacturePrecision" ${disabled}>${precisionOptions(lot.manufacturePrecision)}</select>${icon('chevronDown','icon--sm')}</span></div><div class="form-field" data-ds-component="VTextField" data-figma-node="522:7186"><label>Ngày sản xuất</label><span class="input-shell bj02-date-shell"><span class="bj02-date-leading">${icon('calendar','icon--sm')}</span><input data-bj02-lot-field="manufactureDate" value="${escapeAttribute(lot.manufactureDate)}" placeholder="${manufacturePlaceholder}" inputmode="numeric" ${disabled}/></span></div></div>`:(!locked?`<button class="button button--tertiary lot-extra-action" data-bj02-action="show-manufacture-date" data-ds-component="VButton" type="button">Thêm ngày sản xuất</button>`:'')}
      <div class="section-label"><span>Phân loại số lượng</span></div>${exceptionQuantitiesEditor('lot',t,locked)}${bj02KeyValueRow('Tổng kiểm nhận',`${t.totalReceived} ${lineEditorDraft.uom||''}`,true,'bj02-derived-total')}${t.rejected>0?`<p class="v392-rejected-helper">${t.rejected} ${v392Esc(lineEditorDraft.uom)} từ chối · không vào tồn</p>`:''}<div class="editor-feedback" data-bj02-quantity-feedback>${quantityFeedback(t)}</div><div class="editor-feedback" data-bj02-lot-identity-feedback>${lotIdentityFeedback(lot)}</div>${canRemove&&!locked?`<button class="button button--tertiary lot-delete-action-inline" data-bj02-action="remove-editor-lot" data-bj02-lot-id="${lot.id}" data-ds-component="VButton" type="button">Xóa lô</button>`:''}
    </div></div>`;
  };
  const v392LineEditorValidBase=lineEditorValid;
  lineEditorValid=function(){
    if(!v392LineEditorValidBase()) return false;
    if(lineEditorDraft?.trackingPolicy==='LOT') return (lineEditorDraft.lots||[]).every((lot)=>!lineEditorDraft.expiryRequired || v392ValidPrecisionValue(lot.expiry,lot.expiryPrecision||'DAY'));
    return true;
  };

  function v392EvidencePreviewSheet(){
    if(!V392.evidenceSheetOpen) return '';
    const refs=flowMode==='quick'?v392EvidenceRefs():[{id:documentContext().sourceDocumentRef||selectedDocumentId,name:selectedDocumentId,type:'SOURCE_DOCUMENT'}];
    return `<div class="sheet-backdrop v392-evidence-backdrop" data-v392-close-evidence><section class="bj02-review-detail-sheet v392-evidence-sheet" data-ds-component="VBottomSheet" data-figma-node="4695:6353" role="dialog" aria-modal="true" aria-label="Chứng từ giao nhận" onclick="event.stopPropagation()"><div class="bj02-review-sheet-handle"></div><h2>Chứng từ giao nhận</h2><p class="bj02-review-sheet-context">Bằng chứng đã khóa theo phiên bản yêu cầu gửi duyệt.</p><div class="v392-evidence-list">${refs.map((ref)=>`<div class="v392-evidence-item" data-composed-from="VIconBox,VText"><span>${icon('fileText','icon--sm')}</span><div><strong>${v392Esc(ref.name)}</strong><small>${ref.type==='SOURCE_DOCUMENT'?'Chứng từ nguồn':'Chứng từ giao nhận'}</small></div><button type="button" class="button button--tertiary" data-v392-preview-file>Xem</button></div>`).join('')}</div><button class="button button--secondary button--full" data-v392-close-evidence type="button" data-ds-component="VButton">Đóng</button></section></div>`;
  }
  function v392ChangeSourceSheet(){
    if(!V392.changeSourceConfirmOpen) return '';
    return `<div class="confirm-backdrop" data-v392-cancel-source-change><section class="confirm-dialog" data-ds-component="DS v2 / Confirmation Sheet" data-figma-node="550:1058" role="dialog" aria-modal="true" onclick="event.stopPropagation()"><h3>Đổi chứng từ?</h3><p>Đổi chứng từ sẽ xóa dữ liệu nhận hàng đang nhập để tránh giữ lại số lượng, lô hoặc phiên bản chứng từ không còn đúng.</p><div class="confirm-dialog-actions"><button class="button button--secondary" data-v392-cancel-source-change type="button">Giữ chứng từ</button><button class="button button--primary" data-v392-confirm-source-change type="button">Đổi chứng từ</button></div></section></div>`;
  }

  // Renderers: capability-aware entry, semantic source date, structured quick header, informed approval/result/recovery.
  const r006=renderers['SCR-006'];
  renderers['SCR-006']=function(state){
    if(state==='PERMISSION_DENIED'||state==='LOADING') return r006(state);
    const doc=bj02ListRow({title:'Nhận theo chứng từ',subtitle:'Đã có chứng từ mua để đối chiếu.',attr:'data-flow="document"',disabled:state==='LOCKED',iconName:'fileText'});
    const quick=!V392.capabilities.quickReceipt?'':bj02ListRow({title:'Nhập hàng nhanh',subtitle:V392.quickBlocker||'Hàng đã đến, chưa có chứng từ mua.',attr:'data-flow="quick"',disabled:state==='LOCKED'||Boolean(V392.quickBlocker),iconName:'zap'});
    return appShell({title:'Nhận hàng',body:`${stateBanner(state)}<div class="bj02-choice-stack">${doc}${quick}</div>`,back:false});
  };
  const r007=renderers['SCR-007'];
  renderers['SCR-007']=function(state){
    const html=r007(state);
    return html.replaceAll('2 sản phẩm đang chờ nhận','2 mặt hàng đang chờ nhận').replaceAll('1 sản phẩm','1 mặt hàng');
  };
  renderers['SCR-008']=function(state){
    if(state==='PERMISSION_DENIED') return appShell({title:'Nhập hàng nhanh',body:deniedBody(),centered:true});
    const locked=state==='LOCKED', hasError=['VALIDATION_ERROR','DRAFT_VALIDATION_FAILED'].includes(state);
    const supplierValid=supplierCatalog.some((x)=>x.id===bj02Header.supplierId&&x.name===bj02Header.supplier.trim());
    const evidence=v392EvidenceRefs(), evidenceReady=evidence.length>0;
    const supplierValue=supplierValid?bj02Header.supplier:'Chọn nhà cung cấp';
    const body=`${stateBanner(state)}<section class="v-section compact-section-heading" data-ds-component="VSection"><div class="v-section-copy"><h2 data-ds-component="VText">Thông tin lần nhận</h2><p data-ds-component="VText">Xác định nhà cung cấp, phạm vi nhận và chứng từ giao nhận.</p></div></section><div class="form-stack quick-source-form">
      <div class="form-field supplier-field${locked?' is-disabled':''}" data-ds-component="VSelect" data-figma-node="522:7291"><label>Nhà cung cấp <span class="required">*</span></label><button class="bj02-vselect-trigger${supplierValid?' is-filled':''}${hasError&&!supplierValid?' is-error':''}" data-bj02-open-supplier-sheet type="button" ${locked?'disabled':''}><span>${v392Esc(supplierValue)}</span>${icon('chevronDown','icon--sm')}</button>${hasError&&!supplierValid?'<span class="field-error" data-bj02-supplier-error>Chọn nhà cung cấp trong danh sách.</span>':'<span class="field-error" data-bj02-supplier-error hidden>Chọn nhà cung cấp trong danh sách.</span>'}</div>
      <div class="form-field" data-ds-component="VTextField" data-figma-node="522:7186" data-ds-prop-state="Filled"><label>Kho nhận</label><span class="input-shell is-readonly"><input value="${v392Esc(V392.warehouse.name)}" readonly aria-readonly="true"/></span></div>
      <div class="form-field" data-ds-component="VTextField" data-figma-node="522:7186" data-ds-prop-state="Filled"><label>Ngày nhận</label><span class="input-shell is-readonly"><span class="bj02-date-leading">${icon('calendar','icon--sm')}</span><input value="${v392DateText(bj02Header.businessDate)}" readonly aria-readonly="true"/></span><small>Ngày nghiệp vụ của tenant do hệ thống xác lập.</small></div>
      <div class="form-field" data-ds-component="VFileDropZone" data-figma-node="522:7507"><label>Chứng từ giao nhận <span class="required">*</span></label><label class="file-drop-zone"><input data-bj02-evidence-file type="file" multiple ${locked?'disabled':''}/><span class="file-drop-icon">${icon('cloudUpload','icon--24')}</span><span class="file-drop-copy"><strong>${evidenceReady?'Đã chọn chứng từ':'Chọn hoặc kéo tệp'}</strong><small>${evidenceReady?'Có thể chọn lại để thay bộ chứng từ':'Phiếu giao hàng, biên bản bàn giao, vận đơn hoặc bản scan/ảnh rõ nội dung'}</small></span></label>${evidenceReady?`<div class="v392-evidence-chips">${evidence.map((x)=>`<span>${v392Esc(x.name)}</span>`).join('')}</div>`:''}</div>
      ${vBanner('info','Xác nhận quyền sở hữu','Hệ thống lưu người xác nhận, thời điểm và chứng từ giao nhận.','','Default')}
    </div>${bj02SupplierSelectSheet(locked)}`;
    const disabled=locked||!supplierValid||!evidenceReady||!V392.capabilities.assertOwnership;
    return appShell({title:'Nhập hàng nhanh',body,actions:primaryFooter('Xác nhận & tiếp tục','data-v392-quick-continue',disabled)});
  };

  const r009=renderers['SCR-009'];
  renderers['SCR-009']=function(state){ return r009(state).replaceAll('sản phẩm','mặt hàng'); };
  const r084=renderers['SCR-084'];
  renderers['SCR-084']=function(state){
    const html=r084(state);
    return html.replaceAll('Tổng thực nhận','Tổng kiểm nhận');
  };

  renderers['SCR-010']=function(state){
    if(state==='PERMISSION_DENIED') return appShell({title:'Rà soát nhận hàng',body:deniedBody(),centered:true});
    const pending=state==='PENDING_APPROVAL', priceBlocked=state==='APPROVAL_PRICE_BASIS_REQUIRED'||!v392HasPriceBasis(), approverBlocked=state==='APPROVER_CONFIGURATION_MISSING';
    const requiresApproval=bj02RequiresApproval(), noLines=bj02Lines.length===0, incomplete=!noLines&&!allReceiptLinesHandled();
    const quickZero=flowMode==='quick'&&v392AcceptedPhysicalTotal()===0;
    const disabled=pending||state==='DRAFT_VALIDATION_FAILED'||priceBlocked||approverBlocked||noLines||incomplete||quickZero||(flowMode==='quick'&&!v392OwnershipReady());
    const routeNotice=pending?vBanner('info','Đã gửi phê duyệt','Đang chờ người duyệt; tồn kho chưa thay đổi.','','Compact'):
      priceBlocked?vBanner('error','Chưa đủ căn cứ tính cấp duyệt','Hồ sơ vẫn ở Nháp cho đến khi có căn cứ giá/tỷ giá có phiên bản theo đơn vị cơ sở.'):
      approverBlocked?vBanner('error','Chưa có người duyệt phù hợp','Hồ sơ vẫn ở Nháp. Cần cấu hình người duyệt đủ quyền và phạm vi.'):
      quickZero?vBanner('error','Chưa có hàng vào tồn','Nhập hàng nhanh chỉ gửi được khi Đạt + Cách ly + Hỏng lớn hơn 0.'):
      requiresApproval?(flowMode==='quick'?vBanner('info','Cần phê duyệt trước khi ghi nhận','Nhập hàng nhanh luôn cần người duyệt độc lập. Tồn kho chưa thay đổi.','','Compact'):vBanner('warning','Lượng vào tồn vượt chứng từ','Đạt + Cách ly + Hỏng vượt lượng còn được nhận. Hồ sơ cần phê duyệt.')):'';
    const stateNotice=['PENDING_APPROVAL','APPROVAL_REQUIRED'].includes(state)?'':stateBanner(state);
    const readiness=noLines?`<div class="empty-state bj02-review-empty" data-ds-component="VEmptyState"><div class="icon-box">${icon('package','icon--empty-media')}</div><h3>Chưa có hàng để rà soát</h3><p>Thêm và hoàn tất hàng thực nhận trước khi tiếp tục.</p></div>`:incomplete?vBanner('warning','Còn mặt hàng chưa hoàn tất','Quay lại Hàng thực nhận để hoàn tất từng mặt hàng.') : '';
    // Không cộng chéo transaction-UOM trên Review. Quantity authority vẫn ở từng Product+UOM line;
    // aggregate toàn hồ sơ chỉ dùng cho money risk sau khi normalize về base UOM.
    const physicalSummary=!noLines?`<div class="v392-quantity-summary" data-composed-from="DS v2 / Key-value Row">${bj02KeyValueRow('Mặt hàng đã xử lý',`${bj02ReviewProductCount()} mặt hàng`)}${bj02KeyValueRow('Dòng nhận hàng',`${bj02Lines.length} dòng`,true)}</div>`:'';
    const content=noLines?readiness:`<section class="bj02-review-section" data-ds-component="VSection"><div class="bj02-section-heading"><strong>Thông tin lần nhận</strong>${pending?'':`<button class="inline-edit" ${flowMode==='quick'?'data-next="SCR-008"':'data-v392-change-source'} data-ds-component="VButton" type="button">${flowMode==='quick'?'Sửa':'Đổi chứng từ'}</button>`}</div><div class="bj02-info-stack">${bj02SourceRows()}</div></section><section class="bj02-review-section" data-ds-component="VSection"><div class="bj02-section-heading"><div><strong>Hàng thực nhận</strong><span>${bj02ReviewProductCount()} mặt hàng · ${bj02Lines.length} dòng</span></div>${pending?'':'<button class="inline-edit" data-next="SCR-009" data-ds-component="VButton" type="button">Sửa</button>'}</div>${physicalSummary}<div class="bj02-review-products">${bj02ReviewProductBlocks()}</div></section>${incomplete?readiness:''}`;
    const footer=pending?'':primaryFooter(requiresApproval?'Gửi phê duyệt':'Xác nhận nhận hàng','data-action="submit"',disabled);
    return appShell({title:'Rà soát nhận hàng',body:`${stateNotice}${routeNotice}${content}${bj02ReviewDetailSheet()}${v392ChangeSourceSheet()}`,actions:footer});
  };

  renderers['SCR-011']=function(state){
    if(state==='PERMISSION_DENIED') return appShell({title:'Phê duyệt yêu cầu nhận hàng',subtitle:'Việc dành cho người phê duyệt',body:deniedBody(),centered:true,backAction:'exit-approval'});
    const disabled=['SELF_APPROVAL_NOT_ALLOWED','APPROVAL_ALREADY_DECIDED','PROCESSING'].includes(state), decided=state==='APPROVAL_ALREADY_DECIDED';
    if(!bj02Lines.length) return appShell({title:'Phê duyệt yêu cầu nhận hàng',subtitle:'Việc dành cho người phê duyệt',body:`<div class="empty-state" data-ds-component="VEmptyState"><h3>Không có yêu cầu để duyệt</h3><p>Yêu cầu chỉ xuất hiện sau khi người lập gửi hồ sơ hợp lệ.</p></div>`,centered:true,backAction:'exit-approval'});
    const over=bj02Lines.some((line)=>flowMode==='document'&&lineAcceptedBase(line)>documentLineAllowanceBase(line));
    const reason=!decided?vBanner(flowMode==='quick'?'info':'warning','Lý do cần duyệt',flowMode==='quick'?'Nhập hàng nhanh bắt buộc phê duyệt.':over?'Lượng vào tồn vật lý vượt chứng từ nguồn.':'Hồ sơ được định tuyến theo chính sách phê duyệt.','','Compact'):approvalRejectReason?vBanner('error','Đã từ chối',approvalRejectReason):'';
    const risk=receiptRiskValue();
    const riskRow=V392.capabilities.viewApprovalRiskTotal&&state!=='FINANCIAL_MASKED'?bj02KeyValueRow('Tổng giá trị rủi ro',`${risk.toLocaleString('vi-VN')} đ`,true):bj02InfoRow('Tổng giá trị rủi ro','Không có quyền xem');
    const facts=`${bj02InfoRow('Người gửi',V392.submitted.maker)}${bj02InfoRow('Gửi lúc',V392.submitted.submittedAt)}${riskRow}`;
    const evidenceAction=`<button class="button button--secondary button--full v392-evidence-preview" data-v392-open-evidence type="button" data-ds-component="VButton">${icon('fileText','icon--sm')} Xem chứng từ giao nhận</button>`;
    const body=`${state==='APPROVAL_REQUIRED'?'':stateBanner(state)}${reason}<section class="bj02-review-section" data-ds-component="VSection"><div class="bj02-section-heading"><strong>Thông tin lần nhận</strong></div><div class="bj02-info-stack">${bj02SourceRows()}</div>${evidenceAction}</section><section class="bj02-review-section"><div class="bj02-section-heading"><strong>Thông tin yêu cầu</strong></div><div class="bj02-info-stack">${facts}</div></section><section class="bj02-review-section"><div class="bj02-section-heading"><strong>Hàng thực nhận</strong><span>${bj02ReviewProductCount()} mặt hàng · ${bj02Lines.length} dòng</span></div><div class="bj02-review-products">${bj02ReviewProductBlocks()}</div></section>${bj02ReviewDetailSheet()}${v392EvidencePreviewSheet()}`;
    const footer=decided?'':`<footer class="app-actions is-split approval-actions figma-sticky-footer" data-ds-component="DS v2 / Sticky Footer" data-ds-prop-layout="Dual" data-figma-node="549:927"><button class="button button--secondary" data-action="open-reject" type="button" ${disabled?'disabled':''}>Từ chối</button><button class="button button--primary" data-action="approve" type="button" ${disabled?'disabled':''}>Duyệt</button></footer>`;
    return appShell({title:'Phê duyệt yêu cầu nhận hàng',subtitle:`Việc dành cho người phê duyệt · ${V392.submitted.maker} gửi`,body,actions:footer,backAction:'exit-approval'});
  };

  renderers['SCR-012']=function(state){
    if(state==='PERMISSION_DENIED') return appShell({title:'Kết quả nhận hàng',body:deniedBody(),centered:true});
    if(state==='PROCESSING') return appShell({title:'Kết quả nhận hàng',body:`<div class="loading-state" data-ds-component="VLoading"><span class="v-loading-spinner"></span><strong>Đang ghi nhận hàng</strong><p>Hệ thống đang xử lý. Bạn không cần thực hiện lại.</p></div>`});
    if(['UNKNOWN','COMMIT_UNKNOWN'].includes(state)) return appShell({title:'Kết quả nhận hàng',body:`<div class="loading-state" data-ds-component="VLoading"><span class="v-loading-spinner"></span><strong>Đang xác minh kết quả</strong><p>Không thực hiện lại thao tác nhận hàng.</p></div>${vBanner('warning','Giữ nguyên lần nhận hiện tại','Hệ thống tiếp tục đối soát kết quả của lần nhận này.')}`,actions:primaryFooter('Xác minh kết quả','data-v350-action="bj02-verify-unknown"'),centered:true,back:false});
    if(state==='REJECTED_EXECUTION') return appShell({title:'Kết quả nhận hàng',body:`<div class="empty-state result-empty" data-ds-component="VEmptyState"><h2>Chưa ghi nhận hàng</h2><p>Yêu cầu bị chặn trước khi tồn kho thay đổi.</p></div>`,centered:true});
    const physical=v392AcceptedPhysicalTotal(), zeroImpact=physical===0;
    const hero=zeroImpact?resultHero('Đã ghi nhận kết quả lần nhận','Không có hàng vào tồn vật lý trong lần nhận này.'):resultHero('Đã ghi nhận hàng',`Đã tăng tồn vật lý theo ${bj02Lines.length} dòng hàng được xử lý.`);
    const valuation=state==='VALUATION_PENDING_RESULT'&&physical>0?vBanner('info','Đang chờ xác nhận giá','Phần Đạt chờ xác nhận giá; Cách ly/Hỏng giữ nguyên trạng thái.') : '';
    const body=`${hero}<section class="bj02-review-section result-lines-card"><div class="bj02-section-heading"><strong>Kết quả theo dòng hàng</strong></div><div class="bj02-review-products">${bj02ReviewProductBlocks({interactive:false})}</div></section>${valuation}`;
    return appShell({title:'Kết quả nhận hàng',body,actions:primaryFooter('Xong','data-action="exit-flow"')});
  };

  renderers['SCR-013']=function(state){
    if(state==='LOADING') return appShell({title:'Đối soát nhận hàng',subtitle:'Tự mở khi kết quả lần nhận chưa xác định',body:loadingBody()});
    if(state==='PERMISSION_DENIED') return appShell({title:'Đối soát nhận hàng',subtitle:'Tự mở khi kết quả lần nhận chưa xác định',body:deniedBody(),centered:true});
    if(state==='EMPTY') return appShell({title:'Đối soát nhận hàng',subtitle:'Tự mở khi kết quả lần nhận chưa xác định',body:`<div class="empty-state" data-ds-component="VEmptyState"><h3>Chưa có kết quả mới</h3><p>Hệ thống vẫn đang theo dõi lần nhận này. Bạn không cần tạo lại thao tác.</p></div>`,centered:true});
    const uncertain=['PROCESSING_OR_UNKNOWN','STALE'].includes(state), ev=V392.recoveryEvidence;
    const item=(tone,ico,title,desc,meta)=>`<div class="timeline-item ${tone==='warning'?'is-warning':''}" data-ds-component="DS v2 / Timeline Item" data-figma-node="525:587"><span class="timeline-marker" data-ds-component="VIconBox" data-ds-prop-tone="VComponentTone.${tone}">${icon(ico,'icon--sm')}</span><div class="timeline-content"><strong>${title}</strong><span>${desc}</span><small>${meta}</small></div></div>`;
    let timeline='';
    if(ev.submitted.proven) timeline+=item('neutral','fileText','Hồ sơ nhận đã được khóa',V392.submitted.receiptRef,`${ev.submitted.at} · ${ev.submitted.actor}`);
    if((flowMode==='quick'||bj02RequiresApproval())&&ev.approval.proven) timeline+=item('success','shield','Yêu cầu đã được duyệt',`Người duyệt: ${ev.approval.actor}`,ev.approval.at);
    timeline+=uncertain?item('warning','clock','Đang xác lập kết quả cuối cùng','Kết quả của lần nhận hiện tại','Đang tiếp tục kiểm tra'):ev.operationResult.proven?item('success','check','Kết quả ghi nhận đã được xác lập','Kết quả của lần nhận hiện tại',ev.operationResult.at):'';
    timeline+=uncertain?item('warning','clock','Đang kiểm tra biến động tồn kho','Chưa có bằng chứng xác nhận biến động tồn kho đã được ghi','Không cần tạo lần nhận mới'):ev.inventoryMovement.proven?item('success','package','Biến động tồn kho đã được ghi',`${bj02Lines.length} dòng hàng · mốc sổ ${ev.inventoryMovement.ledgerSequence}`,ev.inventoryMovement.at):'';
    const status=state==='TERMINAL'?vBanner('success','Đã xác lập kết quả','Kết quả cuối cùng đã có; hệ thống sẽ đưa bạn về màn kết quả.'):`<div class="loading-state loading-state--compact" data-ds-component="VLoading"><span class="v-loading-spinner"></span><strong>Đang xác minh kết quả nhận hàng</strong><p>Chưa cần thực hiện lại lần nhận.</p></div>`;
    const body=`${status}${state==='STALE'?stateBanner('STALE'):''}<div class="as-of"><span>Lần kiểm tra gần nhất</span><strong class="mono">${ev.checkedAt}</strong></div><section class="timeline-card" data-ds-component="VSection"><div class="timeline">${timeline}</div></section>${uncertain?`<button class="button button--secondary manual-refresh" data-action="refresh" type="button">${icon('rotate','icon--sm')} Làm mới</button>`:''}`;
    return appShell({title:'Đối soát nhận hàng',subtitle:'Tự mở khi kết quả lần nhận chưa xác định',body,actions:state==='PROCESSING_OR_UNKNOWN'?primaryFooter('Xem hỗ trợ xử lý','data-v350-action="bj02-handoff-unknown"'):''});
  };

  // Capture high-impact interactions before generic v3.9.1 handlers.
  document.addEventListener('change',(event)=>{
    if(event.target.matches('[data-bj02-evidence-file]')){
      const files=[...(event.target.files||[])];
      bj02Header.evidenceRefs=files.map((f,i)=>({id:`EV-${Date.now()}-${i+1}`,name:f.name,type:'DELIVERY_DOCUMENT'}));
      bj02Header.evidence=bj02Header.evidenceRefs[0]?.name||'';
      bj02Header.ownershipAssertion=null;
    }
    if(event.target.matches('[data-v392-lot-precision]')&&lineEditorDraft){
      const lot=lineEditorDraft.lots?.find((x)=>x.id===activeLotDraftId);
      if(lot){ lot[event.target.dataset.v392LotPrecision]=event.target.value; lineEditorDirty=true; }
    }
  },true);
  document.addEventListener('click',(event)=>{
    const quick=event.target.closest('[data-v392-quick-continue]');
    if(quick){
      event.preventDefault(); event.stopImmediatePropagation();
      const supplierValid=supplierCatalog.some((x)=>x.id===bj02Header.supplierId&&x.name===bj02Header.supplier.trim());
      if(!supplierValid||!v392EvidenceRefs().length||!V392.capabilities.assertOwnership) return;
      v392MakeOwnershipAssertion(); return navigate('SCR-009');
    }
    if(event.target.closest('[data-v392-open-evidence]')){event.preventDefault();event.stopImmediatePropagation();V392.evidenceSheetOpen=true;return renderAppScreen();}
    if(event.target.closest('[data-v392-close-evidence]')){event.preventDefault();event.stopImmediatePropagation();V392.evidenceSheetOpen=false;return renderAppScreen();}
    if(event.target.closest('[data-v392-preview-file]')){event.preventDefault();event.stopImmediatePropagation();return showToast('Đã mở bản xem trước chứng từ trong chế độ prototype.','info');}
    if(event.target.closest('[data-v392-change-source]')){event.preventDefault();event.stopImmediatePropagation();V392.changeSourceConfirmOpen=true;return renderAppScreen();}
    if(event.target.closest('[data-v392-cancel-source-change]')){event.preventDefault();event.stopImmediatePropagation();V392.changeSourceConfirmOpen=false;return renderAppScreen();}
    if(event.target.closest('[data-v392-confirm-source-change]')){event.preventDefault();event.stopImmediatePropagation();V392.changeSourceConfirmOpen=false;resetBj02Receipt('document');return navigate('SCR-007');}
  },true);

  // Fresh render so v3.9.2 overrides are visible on direct deep links.
  if(typeof render==='function') render();
})();
