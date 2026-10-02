import { VET45_DS_VERSION, initVet45DS } from "../../../../../vet45-html-design-system/src/vet45-ds.js";

const ICON_MAP = Object.freeze({
  'VIcons.arrowLeft':'chevron-left','VIcons.chevronLeft':'chevron-left','VIcons.arrowRight':'chevron-right','VIcons.chevronRight':'chevron-right','VIcons.arrowDropDown':'chevron-down',
  'VIcons.description':'file-text','li:cloud-upload':'cloud-upload','VIcons.bolt':'zap','VIcons.info':'info','VIcons.warning':'triangle-alert','VIcons.search':'search',
  'VIcons.tune':'sliders-horizontal','VIcons.warehouse':'warehouse','VIcons.calendar':'calendar','VIcons.save':'check','VIcons.inventory':'package','VIcons.check':'check',
  'VIcons.success':'circle-check','VIcons.error':'circle-x','VIcons.close':'x','VIcons.shield':'shield-check','VIcons.person':'user','VIcons.clock':'clock','VIcons.refresh':'refresh-cw',
  'VIcons.lock':'lock','VIcons.inbox':'inbox','VIcons.checkList':'logs','VIcons.moreHoriz':'ellipsis','VIcons.history':'history','VIcons.edit':'pencil','fileText':'file-text','alert':'triangle-alert','checkCircle':'circle-check'
});

const TEMPLATE_MAP = Object.freeze({
  'Mobile / Root List':'root-list','Mobile / Nested List':'nested-list','Mobile / Detail':'detail','Mobile / Form':'form','Mobile / Wizard':'wizard','Mobile / Search & Select':'search-select','Mobile / State':'state','Mobile / Identity':'identity'
});

const qsa=(root,sel)=>Array.from(root.querySelectorAll(sel));
const text=(v)=>String(v||'').toLowerCase();
const add=(el,...cls)=>{ if(el) el.classList.add(...cls.filter(Boolean)); return el; };
const canonical=(el,name)=>{ if(el&&name) el.dataset.dsCanonicalComponent=name; return el; };

function stateFrom(el){
  const raw=text(el.dataset.dsPropState||el.dataset.state);
  if(raw.includes('disable')||el.disabled||el.getAttribute('aria-disabled')==='true') return 'disabled';
  if(raw.includes('select')||raw==='on'||el.classList.contains('is-selected')||el.getAttribute('aria-pressed')==='true') return 'selected';
  if(raw.includes('press')) return 'pressed';
  if(raw.includes('error')||el.classList.contains('is-error')) return 'error';
  return raw && !raw.includes('.') ? raw : 'default';
}
function toneFrom(el, fallback='neutral'){
  const raw=text(el.dataset.dsPropTone||el.dataset.dsPropStatus||el.dataset.tone);
  for(const t of ['success','warning','danger','info','brand']) if(raw.includes(t)) return t;
  const cls=text(el.className);
  for(const t of ['success','warning','danger','info']) if(cls.includes(t)|| (t==='danger'&&cls.includes('error'))) return t;
  return fallback;
}
function buttonHierarchy(el){
  const raw=text(el.dataset.dsPropHierarchy||el.dataset.dsPropVariant||el.dataset.hierarchy);
  if(raw.includes('danger')||text(el.dataset.dsPropTone).includes('danger')||el.classList.contains('button--danger')) return 'danger';
  if(raw.includes('tertiary')||el.classList.contains('button--tertiary')||el.classList.contains('inline-edit')||el.classList.contains('lot-extra-action')||el.classList.contains('lot-delete-action-inline')) return 'tertiary';
  if(raw.includes('secondary')||el.classList.contains('button--secondary')||el.classList.contains('ds24-button--secondary')) return 'secondary';
  return 'primary';
}
function normalizeIcon(el){
  if(el.matches('[data-v-icon]')) return;
  const name=ICON_MAP[el.dataset.dsIcon] || (el.dataset.dsIcon||'').replace(/^VIcons\./,'').replace(/[A-Z]/g,m=>'-'+m.toLowerCase()).replace(/^-/, '') || 'info';
  const span=document.createElement('span');
  span.dataset.vIcon=name;
  const size=el.classList.contains('icon--24')?24:el.classList.contains('icon--sm')?20:el.classList.contains('icon--empty-media')?32:20;
  span.dataset.size=String(size);
  span.dataset.tone=toneFrom(el,'primary');
  if(el.getAttribute('aria-label')) span.setAttribute('aria-label',el.getAttribute('aria-label'));
  el.replaceWith(span);
}
function dsIcon(name,size=20,tone='secondary'){
  const span=document.createElement('span');
  span.dataset.vIcon=name; span.dataset.size=String(size); span.dataset.tone=tone;
  return span;
}
function directFieldLabel(field){
  return field.querySelector(':scope > label,:scope > span:first-child');
}
function cleanLabel(field){
  return String(directFieldLabel(field)?.textContent||'Lựa chọn').replace(/\s*\*\s*$/,'').trim() || 'Lựa chọn';
}
function hideLegacyControlContainer(field,control){
  let node=control.parentElement;
  if(node && node!==field && (node.classList.contains('input-shell')||node.classList.contains('select-shell')||node.classList.contains('bj02-native-select-shell')||node.classList.contains('v430-money'))){
    node.hidden=true;
    return node;
  }
  control.hidden=true;
  return control;
}
function closeAdapterOverlay(product,kind){
  qsa(product,`[data-t7-adapter-overlay="${kind}"]`).forEach(el=>el.remove());
}
function updateSelectTrigger(field,control,trigger){
  const option=control.options?.[control.selectedIndex];
  const value=option?.textContent?.trim() || control.getAttribute('placeholder') || 'Chọn';
  const valueNode=trigger.querySelector('.v-select-shell__value');
  if(valueNode) valueNode.textContent=value;
  if(control.disabled){ field.dataset.state='disabled'; trigger.setAttribute('aria-disabled','true'); trigger.tabIndex=-1; }
  else { trigger.removeAttribute('aria-disabled'); trigger.tabIndex=0; if(field.dataset.state!=='error') field.dataset.state=control.value?'filled':'default'; }
}
function openSelectSheet(field,control,trigger){
  if(control.disabled) return;
  const product=field.closest('[data-mobile-product]'); if(!product) return;
  closeAdapterOverlay(product,'select');
  const overlay=document.createElement('div'); overlay.className='v-overlay'; overlay.dataset.placement='bottom'; overlay.dataset.t7AdapterOverlay='select';
  const sheet=document.createElement('section'); sheet.className='v-select-sheet'; sheet.setAttribute('role','dialog'); sheet.setAttribute('aria-modal','true'); sheet.setAttribute('aria-label',cleanLabel(field));
  const handle=document.createElement('div'); handle.className='v-sheet-handle';
  const title=document.createElement('div'); title.className='v-select-sheet__title'; title.textContent=cleanLabel(field);
  const search=document.createElement('div'); search.className='v-search'; search.dataset.state='default';
  const leading=document.createElement('span'); leading.className='v-search__leading'; leading.appendChild(dsIcon('search',20,'primary'));
  const searchInput=document.createElement('input'); searchInput.className='v-control'; searchInput.placeholder='Tìm kiếm'; searchInput.setAttribute('aria-label',`Tìm trong ${cleanLabel(field)}`);
  search.append(leading,searchInput);
  const results=document.createElement('div'); results.className='v-select-sheet__results';
  const render=()=>{
    const query=text(searchInput.value).trim(); results.replaceChildren();
    Array.from(control.options||[]).filter(opt=>!query||text(opt.textContent).includes(query)).forEach(opt=>{
      const row=document.createElement('button'); row.type='button'; row.className='v-list-row'; row.dataset.type='selection'; row.dataset.density='compact'; row.dataset.state=opt.disabled?'disabled':(opt.value===control.value?'selected':'default'); row.disabled=!!opt.disabled;
      const copy=document.createElement('div'); copy.className='v-list-row__copy'; const rowTitle=document.createElement('div'); rowTitle.className='v-list-row__title'; rowTitle.textContent=opt.textContent||''; copy.appendChild(rowTitle); row.appendChild(copy);
      row.addEventListener('click',()=>{ control.value=opt.value; control.dispatchEvent(new Event('input',{bubbles:true})); control.dispatchEvent(new Event('change',{bubbles:true})); updateSelectTrigger(field,control,trigger); overlay.remove(); });
      results.appendChild(row);
    });
  };
  searchInput.addEventListener('input',render); render();
  sheet.append(handle,title,search,results); overlay.appendChild(sheet); product.appendChild(overlay);
  overlay.addEventListener('click',e=>{ if(e.target===overlay) overlay.remove(); });
  requestAnimationFrame(()=>searchInput.focus());
}
function normalizeNativeSelect(field,control){
  field.dataset.kind='select'; canonical(field,'VSelect');
  control.classList.remove('v-control'); control.hidden=true; control.setAttribute('aria-hidden','true'); control.tabIndex=-1;
  let trigger=field.querySelector(':scope > [data-t7-select-trigger]');
  if(!trigger){
    trigger=document.createElement('div'); trigger.className='v-select-shell'; trigger.dataset.t7SelectTrigger='true'; trigger.setAttribute('role','combobox'); trigger.setAttribute('aria-haspopup','dialog');
    const value=document.createElement('span'); value.className='v-select-shell__value'; trigger.append(value,dsIcon('chevron-down',20,'secondary'));
    const label=directFieldLabel(field); const top=control.parentElement!==field?control.parentElement:control;
    if(top!==control && top!==field) top.hidden=true;
    field.insertBefore(trigger, top===field?control:top);
    control.addEventListener('change',()=>updateSelectTrigger(field,control,trigger));
  }
  updateSelectTrigger(field,control,trigger);
}
function normalizeCustomSelectTrigger(field,trigger){
  add(trigger,'v-select-shell'); canonical(field,'VSelect'); field.dataset.kind='select';
  const value=trigger.querySelector(':scope > span:first-child'); if(value)add(value,'v-select-shell__value');
  const legacyIcon=trigger.querySelector('[data-ds-component="VIcon"],svg.icon'); if(legacyIcon) normalizeIcon(legacyIcon);
  const filled=trigger.classList.contains('is-filled') || (value&&value.textContent.trim()&&!/^(chọn|nhập)/i.test(value.textContent.trim()));
  if(trigger.disabled) field.dataset.state='disabled'; else if(field.dataset.state!=='error') field.dataset.state=filled?'filled':'default';
}
function normalizeMoneyField(field,control){
  field.dataset.kind='money'; canonical(field,'VMoneyField'); control.classList.remove('v-control');
  let shell=control.closest('.v-money-shell');
  if(!shell){ shell=control.parentElement!==field?control.parentElement:null; if(!shell||!shell.querySelector('input')){shell=document.createElement('div');control.before(shell);shell.appendChild(control);} add(shell,'v-money-shell'); }
  const currency=Array.from(shell.children).find(el=>el!==control && el.matches('span,small'));
  if(currency)add(currency,'v-money-shell__currency');
}
function dateValue(control){ return control.value?.trim() || control.getAttribute('placeholder') || 'dd/mm/yyyy'; }
function updateDateTrigger(field,control,trigger){
  const value=trigger.querySelector('.v-date-shell__value'); if(value)value.textContent=dateValue(control);
  if(control.disabled){field.dataset.state='disabled';trigger.setAttribute('aria-disabled','true');trigger.tabIndex=-1;}else{trigger.removeAttribute('aria-disabled');trigger.tabIndex=0;if(field.dataset.state!=='error')field.dataset.state=control.value?'filled':'default';}
}
function openDateSheet(field,control,trigger){
  if(control.disabled)return; const product=field.closest('[data-mobile-product]'); if(!product)return; closeAdapterOverlay(product,'date');
  const overlay=document.createElement('div'); overlay.className='v-overlay'; overlay.dataset.placement='bottom'; overlay.dataset.t7AdapterOverlay='date';
  const sheet=document.createElement('section'); sheet.className='v-form-sheet'; sheet.setAttribute('role','dialog'); sheet.setAttribute('aria-modal','true'); sheet.setAttribute('aria-label',cleanLabel(field));
  const handleArea=document.createElement('div'); handleArea.className='v-form-sheet__handle-area'; const handle=document.createElement('div'); handle.className='v-form-sheet__handle'; handleArea.appendChild(handle);
  const header=document.createElement('div'); header.className='v-form-sheet__header'; const title=document.createElement('div'); title.className='v-form-sheet__title'; title.textContent=cleanLabel(field); header.appendChild(title);
  const fields=document.createElement('div'); fields.className='v-form-sheet__fields'; const editField=document.createElement('label'); editField.className='v-field'; editField.dataset.kind='text'; const label=document.createElement('span'); label.className='v-field__label'; label.textContent=cleanLabel(field); const draft=document.createElement('input'); draft.className='v-control v-mono'; draft.value=control.value||''; draft.placeholder=control.getAttribute('placeholder')||'dd/mm/yyyy'; draft.inputMode=control.inputMode||'numeric'; editField.append(label,draft); fields.appendChild(editField);
  const footer=document.createElement('div'); footer.className='v-sticky-footer'; footer.dataset.layout='single'; const apply=document.createElement('button'); apply.type='button'; apply.className='v-btn v-grow'; apply.dataset.hierarchy='primary'; apply.dataset.size='default'; apply.dataset.width='fill'; apply.textContent='Áp dụng'; footer.appendChild(apply);
  apply.addEventListener('click',()=>{control.value=draft.value;control.dispatchEvent(new Event('input',{bubbles:true}));control.dispatchEvent(new Event('change',{bubbles:true}));updateDateTrigger(field,control,trigger);overlay.remove();});
  sheet.append(handleArea,header,fields,footer); overlay.appendChild(sheet); product.appendChild(overlay); overlay.addEventListener('click',e=>{if(e.target===overlay)overlay.remove();}); requestAnimationFrame(()=>draft.focus());
}
function normalizeDateField(field,control){
  field.dataset.kind='date'; canonical(field,'VDatePicker'); control.classList.remove('v-control'); control.hidden=true; control.setAttribute('aria-hidden','true'); control.tabIndex=-1;
  let trigger=field.querySelector(':scope > [data-t7-date-trigger]');
  if(!trigger){ trigger=document.createElement('div'); trigger.className='v-date-shell'; trigger.dataset.t7DateTrigger='true'; trigger.setAttribute('role','button'); const value=document.createElement('span'); value.className='v-date-shell__value'; trigger.append(value,dsIcon('clock',20,'secondary')); const top=control.parentElement!==field?control.parentElement:control; if(top!==control&&top!==field)top.hidden=true; field.insertBefore(trigger,top===field?control:top); control.addEventListener('input',()=>updateDateTrigger(field,control,trigger)); control.addEventListener('change',()=>updateDateTrigger(field,control,trigger)); }
  updateDateTrigger(field,control,trigger);
}
function normalizeShell(product){
  add(product,'v-template'); canonical(product, product.dataset.figmaTemplate||'Mobile / Detail');
  const template=TEMPLATE_MAP[product.dataset.figmaTemplate] || product.dataset.template || (product.querySelector('.app-actions')?'detail':'nested-list');
  product.dataset.template=template;
  product.dataset.htmlDsVersion=VET45_DS_VERSION;
  const sb=product.querySelector('.app-statusbar'); add(sb,'v-template__statusbar'); qsa(sb||product,':scope > span').forEach(el=>add(el,'v-caption'));
  // Canonical template anatomy requires the VAppBar to be a direct child of .v-template.
  const legacyHeader=product.querySelector(':scope > .app-header');
  const nestedAppbar=legacyHeader?.querySelector(':scope > .app-appbar');
  if(legacyHeader&&nestedAppbar) legacyHeader.replaceWith(nestedAppbar);
  const appbar=product.querySelector(':scope > .app-appbar');
  add(appbar,'v-appbar');
  const back=product.querySelector('.app-back-button'); add(back,'v-appbar__leading','v-icon-btn');
  const copy=product.querySelector('.app-appbar-copy'); add(copy,'v-appbar__copy');
  add(copy?.querySelector('h3'),'v-appbar__title'); add(copy?.querySelector('span'),'v-appbar__subtitle');
  const content=product.querySelector('.app-content'); add(content,'v-template__scroll');
  if(content){ content.dataset.withAppbar='true'; if(product.querySelector('.app-actions')) content.dataset.withFooter='true'; }
  const body=product.querySelector('.body-stack'); add(body,'v-stack');
  const footer=product.querySelector('.app-actions');
  if(footer){ add(footer,'v-sticky-footer'); const n=footer.querySelectorAll(':scope > button').length; footer.dataset.layout=n>1?'dual':'single'; }
}
function normalizeButtons(root){
  qsa(root,'[data-ds-component="VButton"],button.button,button.ds24-button').forEach(el=>{
    add(el,'v-btn'); canonical(el,'VButton'); el.dataset.hierarchy=buttonHierarchy(el); el.dataset.size=text(el.dataset.dsPropSize).includes('small')?'small':text(el.dataset.dsPropSize).includes('large')?'large':'default';
    if(el.disabled) el.dataset.state='disabled';
    if(text(el.dataset.dsPropFullWidth)==='true'||el.classList.contains('button--full')){ el.dataset.width='fill'; add(el,'v-grow'); }
  });
  qsa(root,'[data-ds-component="DS v2 / Link"]').forEach(el=>{add(el,'v-link');canonical(el,'DS v2 / Link');});
  qsa(root,'[data-ds-component="DS v2 / Icon Button"]').forEach(el=>{add(el,'v-icon-btn');canonical(el,'DS v2 / Icon Button');});
  qsa(root,'[data-ds-component="VQuickActionButton"]').forEach(el=>{add(el,'v-btn');canonical(el,'VButton');el.dataset.hierarchy='secondary';});
}
function normalizeFields(root){
  const kinds={VTextField:'text',VTextarea:'textarea',VNumberField:'text',VMoneyField:'money',VSelect:'select',VDateField:'date',VDatePickerField:'date',VDatePicker:'date'};
  Object.entries(kinds).forEach(([name,kind])=>qsa(root,`[data-ds-component="${name}"]`).forEach(el=>{
    const field=el.matches('input,select,textarea')?el.closest('label,div')||el:el;
    add(field,'v-field'); canonical(field,name==='VNumberField'?'VTextField':name==='VDateField'||name==='VDatePickerField'?'VDatePicker':name); field.dataset.kind=kind;
    const st=stateFrom(field); if(st!=='default') field.dataset.state=st;
    const control=field.matches('input,select,textarea')?field:field.querySelector('input,select,textarea');
    const label=directFieldLabel(field); if(label&&!label.matches('input,select,textarea')) add(label,'v-field__label');
    const helper=field.querySelector('.helper-text,.field-helper,.field-error,.field-help,:scope > small'); if(helper) add(helper,'v-helper');
    if(kind==='select'){
      const custom=field.querySelector(':scope > button.bj02-vselect-trigger,:scope > .ds24-select-trigger');
      if(control?.matches('select')) normalizeNativeSelect(field,control); else if(custom) normalizeCustomSelectTrigger(field,custom);
    } else if(kind==='money'&&control) normalizeMoneyField(field,control);
    else if(kind==='date'&&control) normalizeDateField(field,control);
    else add(control,'v-control');
  }));
  qsa(root,'[data-ds-component="VField"]').forEach(el=>{
    const c=el.querySelector('select,textarea,input'); if(!c)return; add(el,'v-field');
    const kind=c.matches('select')?'select':c.matches('textarea')?'textarea':'text'; el.dataset.kind=kind; canonical(el,kind==='select'?'VSelect':kind==='textarea'?'VTextarea':'VTextField');
    const lab=directFieldLabel(el); if(lab)add(lab,'v-field__label'); const help=el.querySelector('small,.helper-text');if(help)add(help,'v-helper');
    if(kind==='select') normalizeNativeSelect(el,c); else add(c,'v-control');
  });
  qsa(root,'[data-ds-component="VSearchBar"],.ds24-search').forEach(el=>{
    const search=el.matches('input')?el.parentElement:el; add(search,'v-search'); canonical(search,'VSearchBar'); const input=search.querySelector('input'); add(input,'v-control');
    const icon=search.querySelector('[data-ds-component="VIcon"],svg.icon,[data-v-icon]'); if(icon) add(icon,'v-search__leading');
  });
  qsa(root,'.ds24-field:not([data-ds-component])').forEach(field=>{
    add(field,'v-field'); const label=field.querySelector(':scope > span:first-child'); add(label,'v-field__label');
    const qty=field.querySelector(':scope > .ds24-quantity-trigger');
    if(qty){ add(qty,'v-control-shell'); canonical(field,'VNumericKeypadSheet trigger composition'); field.dataset.kind='text'; const value=qty.querySelector('span'); if(value)add(value,'v-grow'); }
    const select=field.querySelector(':scope > .ds24-select-trigger');
    if(select) normalizeCustomSelectTrigger(field,select);
  });
  qsa(root,'[data-ds-component="VRadio"],.v364-radio-option,.val14-choice-row,.ac310-radio-row').forEach(el=>{
    add(el,'v-checkrow'); canonical(el,'VRadio'); el.dataset.kind='radio'; const st=stateFrom(el); el.dataset.state=(st==='selected'?'on':st==='disabled'?'disabled-off':'off');
    const c=el.querySelector('.v364-radio-control,.val14-radio-control,.ac310-radio-control,.io06-radio,.v-radio'); add(c,'v-radio');
  });
  qsa(root,'[data-ds-component="VCheckbox"]').forEach(el=>{add(el,'v-checkrow');canonical(el,'VCheckbox');el.dataset.kind='checkbox';el.dataset.state=stateFrom(el)==='selected'?'on':'off';const c=el.querySelector('.checkbox-control,.v-checkbox');add(c,'v-checkbox');});
  qsa(root,'[data-ds-component="VSegmentedControl"]').forEach(el=>{add(el,'v-segmented');canonical(el,'VSegmentedControl');});
  qsa(root,'[data-ds-component="VSegmentedControlItem"]').forEach(el=>{add(el,'v-segmented__item');canonical(el,'VSegmentedControl'); if(stateFrom(el)==='selected')el.dataset.selected='true';});
}
function normalizeDisplay(root){
  qsa(root,'[data-ds-component="VBadge"],.status-badge,.ds24-badge').forEach(el=>{add(el,'v-badge');canonical(el,'VBadge');el.dataset.tone=toneFrom(el);});
  qsa(root,'[data-ds-component="VChip"],.ds24-chip').forEach(el=>{add(el,'v-chip');canonical(el,'VChip');el.dataset.tone=(stateFrom(el)==='selected'?'brand':toneFrom(el,'neutral')); if(el.disabled) el.dataset.state='disabled';});
  qsa(root,'[data-ds-component="DS v2 / List Row"],.ds24-list-row,.bj02-ds-list-row').forEach(el=>{
    add(el,'v-list-row'); canonical(el,'DS v2 / List Row'); { const wantsCompact=text(el.dataset.dsPropDensity).includes('compact'); const hasSupport=!!el.querySelector('small,.ds24-list-row__support,.v-list-row__support,.bj02-review-summary-copy span'); el.dataset.density=(wantsCompact&&!hasSupport&&!el.classList.contains('bj02-review-summary-row'))?'compact':'default'; } const rowType=text(el.dataset.dsPropType); el.dataset.type=rowType.includes('selection')?'selection':rowType.includes('status')?'status':'navigation'; const st=stateFrom(el); if(st!=='default')el.dataset.state=st;
    const copy=el.querySelector('.ds24-list-row__copy,.bj02-ds-list-copy,.bj02-review-summary-copy,.io-product-copy,.v-list-row__copy,.v-grow'); add(copy,'v-list-row__copy');
    const title=copy?.querySelector('strong,.ds24-list-row__title,.v-list-row__title'); add(title,'v-list-row__title'); const support=copy?.querySelector('small,span:not(.v-list-row__title),.ds24-list-row__support,.v-list-row__support'); add(support,'v-list-row__support');
  });
  qsa(root,'[data-ds-component="DS v2 / Info Row"],.ds24-info-row,.bj02-info-row,.io-meta-row').forEach(el=>{add(el,'v-info-row');canonical(el,'DS v2 / Info Row'); const kids=Array.from(el.children); add(kids[0],'v-info-row__label'); add(kids[kids.length-1],'v-info-row__value');});
  qsa(root,'[data-ds-component="DS v2 / Key-value Row"],.ds24-key-value-row,.bj02-key-value-row').forEach(el=>{add(el,'v-kv-row');canonical(el,'DS v2 / Key-value Row'); const kids=Array.from(el.children); add(kids[0],'v-kv-row__key'); add(kids[kids.length-1],'v-kv-row__value'); if(text(el.dataset.dsPropState).includes('emphasis')||el.classList.contains('is-emphasis')||el.classList.contains('ds24-key-value-row--emphasis'))el.dataset.state='emphasis';});
  qsa(root,'[data-ds-component="DS v2 / Record Card"],.bj02-record-card').forEach(el=>{add(el,'v-record-card');canonical(el,'DS v2 / Record Card');});
  qsa(root,'[data-ds-component="DS v2 / Summary Card"],.ds24-summary-card').forEach(el=>{add(el,'v-summary-card','v-card');canonical(el,'DS v2 / Summary Card');add(el.querySelector('.ds24-summary-card__title'),'v-summary-card__title');add(el.querySelector('.ds24-summary-card__body'),'v-summary-card__body');});
  qsa(root,'[data-ds-component="DS v2 / Metric Card"],.ac310-metric').forEach(el=>{add(el,'v-metric-card','v-card');canonical(el,'DS v2 / Metric Card'); const val=el.querySelector('strong,.value'); add(val,'v-metric-card__value');});
  qsa(root,'[data-ds-component="DS v2 / Audit Item"],.ac310-audit-item').forEach(el=>{add(el,'v-audit-item');canonical(el,'DS v2 / Audit Item');add(el.querySelector('.ac310-audit-item__copy'),'v-audit-item__copy');});
  qsa(root,'[data-ds-component="DS v2 / Timeline Item"],.timeline-item').forEach(el=>{add(el,'v-timeline-item');canonical(el,'DS v2 / Timeline Item'); const marker=el.querySelector('.timeline-marker'); if(marker){add(marker,'v-timeline-item__rail'); if(!marker.querySelector('.v-timeline-item__dot')) marker.innerHTML='<span class="v-timeline-item__dot"></span><span class="v-timeline-item__line"></span>';}});
  qsa(root,'[data-ds-component="VSection"]').forEach(el=>{add(el,'v-section');el.dataset.dsRole='composition';});
  qsa(root,'.bj02-section-heading,.ds24-section-title,.compact-section-heading,.io-section-title,.ac310-surface__head,.review-card-header,.lot-section-heading').forEach(el=>{add(el,'v-row');const strong=el.querySelector('strong');if(strong)add(strong,'v-h4');const support=el.querySelector('span');if(support)add(support,'v-caption','v-muted');const copy=strong?.parentElement;if(copy&&copy!==el&&support&&copy.contains(support))add(copy,'v-stack-2','v-grow');});
  qsa(root,'[data-ds-component="VPageScaffold"]').forEach(el=>add(el,'v-page-scaffold'));
  qsa(root,'[data-ds-component="VPagePadding"]').forEach(el=>{ if(!['form','wizard'].includes(root.closest?.('[data-mobile-product]')?.dataset.template||'')) add(el,'v-page-padding'); });
  qsa(root,'[data-ds-component="VIconBox"],.icon-box').forEach(el=>add(el,'v-icon-box'));
  qsa(root,'[data-ds-component="VText"]').forEach(el=>{const c=el.matches('h1,h2')?'v-h2':el.matches('h3')?'v-h3':el.matches('h4,strong')?'v-label':el.matches('small')?'v-caption':'v-body';add(el,c);el.dataset.dsFoundation='Typography';});
  qsa(root,'[data-ds-component="DS v2 / List Top Bar"]').forEach(el=>{add(el,'v-list-topbar');canonical(el,'DS v2 / List Top Bar');});
  qsa(root,'[data-ds-component="DS v2 / Readiness Item"]').forEach(el=>{add(el,'v-readiness');canonical(el,'DS v2 / Readiness Item');});
  qsa(root,'[data-ds-component="DS v2 / Search Results Dropdown"]').forEach(el=>{add(el,'v-search-results');canonical(el,'DS v2 / Search Results Dropdown');});
  qsa(root,'[data-ds-component="DS v2 / Search & Filter Header"]').forEach(el=>{add(el,'v-search-filter-header');canonical(el,'DS v2 / Search & Filter Header');});
  qsa(root,'[data-ds-component="VAppBar"]').forEach(el=>{add(el,'v-appbar');canonical(el,'VAppBar');});
  qsa(root,'[data-ds-component="VAppBarTitle"]').forEach(el=>{const slot=el.matches('h1,h2,h3,h4')?el:el.querySelector('h1,h2,h3,h4')||el;add(slot,'v-appbar__title');canonical(el,'VAppBar');});
  qsa(root,'[data-ds-component="VAppBarSubtitle"]').forEach(el=>{add(el,'v-appbar__subtitle');canonical(el,'VAppBar');});
  qsa(root,'[data-ds-component="VCardIcon"]').forEach(el=>add(el,'v-card-icon'));
  qsa(root,'[data-ds-component="VCardTitle"]').forEach(el=>add(el,'v-card-title'));
}
function normalizeFeedback(root){
  qsa(root,'[data-ds-component="VBanner"],.v-banner').forEach(el=>{add(el,'v-banner');canonical(el,'VBanner');el.dataset.tone=toneFrom(el,'info');{ const wantsCompact=text(el.dataset.dsPropDensity).includes('compact'); const hasSupport=!!el.querySelector('small,.ds24-list-row__support,.v-list-row__support,.bj02-review-summary-copy span'); el.dataset.density=(wantsCompact&&!hasSupport&&!el.classList.contains('bj02-review-summary-row'))?'compact':'default'; }const copy=el.querySelector('.v-banner-copy,.v-banner__copy');add(copy,'v-banner__copy');add(copy?.querySelector('strong'),'v-banner__title');add(copy?.querySelector('span'),'v-banner__message');});
  qsa(root,'[data-ds-component="VEmptyState"],.empty-state').forEach(el=>{add(el,'v-empty-state');canonical(el,'VEmptyState');const media=el.querySelector('[data-ds-component="VEmptyMedia"],.icon-box');const title=el.querySelector('[data-ds-component="VEmptyTitle"],h3');const desc=el.querySelector('[data-ds-component="VEmptyDescription"],p');add(media,'v-empty-state__icon');add(title,'v-empty-state__title');add(desc,'v-empty-state__description');canonical(media,'VEmptyState');canonical(title,'VEmptyState');canonical(desc,'VEmptyState');});
  qsa(root,'[data-ds-component="Loading Overlay"]').forEach(el=>{add(el,'v-loading-overlay');canonical(el,'Loading Overlay');el.dataset.mode=el.dataset.mode||'content';const content=el.querySelector('.v-loading-overlay__content');add(content,'v-loading-overlay__content');const label=el.querySelector('.v-loading-overlay__label');add(label,'v-loading-overlay__label');});
  qsa(root,'[data-ds-component="VLoading"],.v-loading-spinner,.generic-spinner').forEach(el=>{if(el.dataset.dsComponent==='Loading Overlay')return;add(el,'v-loading');canonical(el,'VLoading');el.dataset.size=el.dataset.size||'24';});
  qsa(root,'[data-ds-component="VFileDropZone"]').forEach(el=>{const zone=el.matches('.file-drop-zone,.io06-file-control')?el:(el.querySelector('.file-drop-zone,.io06-file-control')||el);add(zone,'v-dropzone');canonical(el,'VFileDropZone');canonical(zone,'VFileDropZone');const copy=zone.querySelector('.file-drop-copy');add(copy,'v-stack-2');add(copy?.querySelector('strong'),'v-dropzone__title');add(copy?.querySelector('small,span'),'v-dropzone__support');});
  qsa(root,'[data-ds-component="VSkeleton"]').forEach(el=>{add(el,'v-skeleton');canonical(el,'VSkeleton');if(!el.dataset.type)el.dataset.type='line';});
  qsa(root,'[data-ds-component="VProgress"]').forEach(el=>{add(el,'v-progress');canonical(el,'VProgress');if(!el.dataset.type)el.dataset.type='linear';});
  qsa(root,'[data-ds-component="VToast"]').forEach(el=>{add(el,'v-toast');canonical(el,'VToast');});
}
function normalizeSurfaces(root){
  qsa(root,'.ds24-info-group,.review-card,.io-read-card,.ac310-surface,.ac310-list-surface,.cr-fact-card,.bj05-section,.io06-section').forEach(el=>{
    if(el.classList.contains('v-list-row')||el.classList.contains('v-banner')) return; add(el,'v-card');
    const title=el.querySelector(':scope > .ds24-info-group__title,:scope > .review-card-header,:scope > .ac310-surface__head,:scope > .bj02-section-heading');
    if(title) add(title,'v-card-header');
    const body=el.querySelector(':scope > .ds24-info-group__rows,:scope > .review-card-body,:scope > .ac310-info-rows'); if(body) add(body,'v-card-content');
  });
}
function normalizeOverlays(root){
  qsa(root,'.sheet-backdrop,.confirm-backdrop,.bottom-sheet-backdrop').forEach(el=>{add(el,'v-overlay');el.dataset.placement='bottom';});
  qsa(root,'[data-ds-component="VBottomSheet"],.bottom-sheet').forEach(el=>{add(el,'v-bottom-sheet');canonical(el,'VBottomSheet');add(el.querySelector('.sheet-handle,.bottom-sheet-handle'),'v-bottom-sheet__handle');add(el.querySelector('.sheet-title h3,.sheet-title,.bottom-sheet-title'),'v-bottom-sheet__title');add(el.querySelector('.sheet-content,.bottom-sheet-content'),'v-bottom-sheet__content');});
  qsa(root,'[data-ds-component="DS v2 / Confirmation Sheet"],.confirm-dialog').forEach(el=>{add(el,'v-confirmation-sheet');canonical(el,'DS v2 / Confirmation Sheet');const h=el.querySelector('h2,h3');add(h,'v-h3');const p=el.querySelector('p');add(p,'v-body','v-muted');add(el.querySelector('.confirm-dialog-actions,.ds24-confirmation__actions'),'v-confirmation-sheet__actions');});
  qsa(root,'[data-ds-component="DS v2 / Select Sheet"]').forEach(el=>{add(el,'v-select-sheet');canonical(el,'DS v2 / Select Sheet');});
  qsa(root,'[data-ds-component="DS v2 / Form Sheet"]').forEach(el=>{add(el,'v-form-sheet');canonical(el,'DS v2 / Form Sheet');});
  qsa(root,'[data-ds-component="VNumericKeypadSheet"]').forEach(el=>{
    add(el,'v-numeric-keypad');canonical(el,'VNumericKeypadSheet');
    const handle=el.querySelector('.ds24-keypad__handle');
    if(handle){ add(handle,'v-numeric-keypad__handle'); if(!handle.parentElement.classList.contains('v-numeric-keypad__handle-area')){const area=document.createElement('div');area.className='v-numeric-keypad__handle-area';handle.before(area);area.appendChild(handle);} }
    const header=el.querySelector(':scope > header');add(header,'v-numeric-keypad__header');add(header?.querySelector('h2,h3'),'v-numeric-keypad__title');add(header?.querySelector('p'),'v-numeric-keypad__subtitle');
    add(el.querySelector('.ds24-keypad__value'),'v-numeric-keypad__value');
    const grid=el.querySelector('.ds24-keypad__grid');add(grid,'v-keypad-grid');qsa(grid||el,'[data-ic08-key]').forEach(k=>add(k,'v-keypad-key'));
    add(el.querySelector('.ds24-keypad__actions'),'v-numeric-keypad__actions');
  });
}
function normalizeCanonicalPatterns(root){
  qsa(root,'[data-ds-component="DS v2 / Sticky Footer"],.app-actions').forEach(el=>{add(el,'v-sticky-footer');canonical(el,'DS v2 / Sticky Footer');});
  qsa(root,'[data-ds-component="DS v2 / Form Sheet"]').forEach(el=>{add(el,'v-form-sheet');canonical(el,'DS v2 / Form Sheet');});
  qsa(root,'[data-ds-component="DS v2 / Search Results Dropdown"]').forEach(el=>{add(el,'v-search-results');canonical(el,'DS v2 / Search Results Dropdown');});
}
function normalizeTypographyUtilities(root){
  qsa(root,'.mono').forEach(el=>add(el,'v-mono'));
  qsa(root,'.secondary').forEach(el=>add(el,'v-muted'));
  qsa(root,'.result-hero h2,.result-hero h3').forEach(el=>add(el,'v-h2'));
  qsa(root,'.result-hero p').forEach(el=>add(el,'v-body','v-muted'));
}
function normalizeIcons(root){ qsa(root,'[data-ds-component="VIcon"]:not([data-v-icon])').forEach(normalizeIcon); }

function sanitizeDsAnnotations(root){
  const aliasMap={VNumberField:'VTextField',VDateField:'VDatePicker',VDatePickerField:'VDatePicker',VQuickActionButton:'VButton'};
  const slotMap={VAppBarTitle:'appbar-title',VAppBarSubtitle:'appbar-subtitle',VEmptyMedia:'empty-media',VEmptyTitle:'empty-title',VEmptyDescription:'empty-description',VSegmentedControlItem:'segmented-item',VCardIcon:'card-icon',VCardTitle:'card-title'};
  const compositionMap={VSection:'section',VPageScaffold:'page-scaffold',VPagePadding:'page-padding',VIconBox:'icon-box',VField:'field-wrapper'};
  qsa(root,'[data-ds-component]').forEach(el=>{
    const raw=el.dataset.dsComponent;
    if(aliasMap[raw]){el.dataset.dsComponent=aliasMap[raw];canonical(el,aliasMap[raw]);return;}
    if(slotMap[raw]){el.dataset.dsSlot=slotMap[raw];delete el.dataset.dsComponent;delete el.dataset.dsCanonicalComponent;return;}
    if(compositionMap[raw]){el.dataset.dsRole=compositionMap[raw];delete el.dataset.dsComponent;delete el.dataset.dsCanonicalComponent;return;}
    if(raw==='VText'){el.dataset.dsFoundation='Typography';delete el.dataset.dsComponent;delete el.dataset.dsCanonicalComponent;return;}
    if(raw==='VIcon'){el.dataset.dsFoundation='Icons';delete el.dataset.dsComponent;delete el.dataset.dsCanonicalComponent;return;}
  });
}


function wireAdapterTriggers(host){
  if(window.__VET45_T7_DS_ADAPTER_TRIGGERS__) return;
  window.__VET45_T7_DS_ADAPTER_TRIGGERS__=true;
  document.addEventListener('click',event=>{
    const select=event.target.closest?.('[data-t7-select-trigger]');
    if(select&&host.contains(select)){
      event.preventDefault(); event.stopPropagation();
      const field=select.closest('.v-field'); const control=field?.querySelector('select');
      if(field&&control) openSelectSheet(field,control,select);
      return;
    }
    const date=event.target.closest?.('[data-t7-date-trigger]');
    if(date&&host.contains(date)){
      event.preventDefault(); event.stopPropagation();
      const field=date.closest('.v-field'); const control=field?.querySelector('input');
      if(field&&control) openDateSheet(field,control,date);
    }
  },true);
  document.addEventListener('keydown',event=>{
    if(!['Enter',' '].includes(event.key)) return;
    const trigger=event.target.closest?.('[data-t7-select-trigger],[data-t7-date-trigger]');
    if(trigger&&host.contains(trigger)){ event.preventDefault(); trigger.click(); }
  },true);
}

function alignTheme7ToDs16(root=document){
  const product=root.matches?.('[data-mobile-product]')?root:root.querySelector?.('[data-mobile-product]'); if(!product) return;
  normalizeShell(product); normalizeButtons(product); normalizeFields(product); normalizeDisplay(product); normalizeFeedback(product); normalizeSurfaces(product); normalizeOverlays(product); normalizeCanonicalPatterns(product); normalizeTypographyUtilities(product); normalizeIcons(product); sanitizeDsAnnotations(product);
  if(product.dataset.vet45DsInitialized!=='true'){ initVet45DS(product); product.dataset.vet45DsInitialized='true'; }
}
window.alignVet45Ds16=alignTheme7ToDs16;

const host=document.getElementById('app-screen');
if(host){
  wireAdapterTriggers(host);
  const run=()=>alignTheme7ToDs16(host);
  const config={childList:true,subtree:true};
  let scheduled=false, running=false;
  const observer=new MutationObserver(()=>{
    if(scheduled||running) return;
    scheduled=true;
    queueMicrotask(()=>{
      scheduled=false; running=true; observer.disconnect();
      try{ run(); } finally { running=false; observer.observe(host,config); }
    });
  });
  run();
  observer.observe(host,config);
}
