import { initVet45DS, VET45_DS_VERSION } from '../../../../../vet45-html-design-system/src/vet45-ds.js';

const ICON_MAP = Object.freeze({
  'VIcons.arrowLeft':'chevron-left','VIcons.chevronLeft':'chevron-left','VIcons.arrowRight':'chevron-right','VIcons.chevronRight':'chevron-right','VIcons.arrowDropDown':'chevron-down',
  'VIcons.description':'file-text','li:cloud-upload':'cloud-upload','VIcons.bolt':'zap','VIcons.info':'info','VIcons.warning':'triangle-alert','VIcons.search':'search',
  'VIcons.tune':'sliders-horizontal','VIcons.warehouse':'warehouse','VIcons.calendar':'calendar','VIcons.save':'check','VIcons.inventory':'package','VIcons.check':'check',
  'VIcons.success':'circle-check','VIcons.error':'circle-x','VIcons.close':'x','VIcons.shield':'shield-check','VIcons.person':'user','VIcons.clock':'clock','VIcons.refresh':'refresh-cw',
  'VIcons.lock':'lock','VIcons.inbox':'inbox','VIcons.checkList':'logs','VIcons.moreHoriz':'ellipsis','VIcons.history':'history','VIcons.edit':'pencil'
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
function normalizeShell(product){
  add(product,'v-template'); canonical(product, product.dataset.figmaTemplate||'Mobile / Detail');
  const template=TEMPLATE_MAP[product.dataset.figmaTemplate] || product.dataset.template || (product.querySelector('.app-actions')?'detail':'nested-list');
  product.dataset.template=template;
  product.dataset.htmlDsVersion=VET45_DS_VERSION;
  const sb=product.querySelector('.app-statusbar'); add(sb,'v-template__statusbar');
  const appbar=product.querySelector('.app-appbar');
  add(appbar,'v-appbar');
  const back=product.querySelector('.app-back-button'); add(back,'v-appbar__leading','v-icon-btn');
  const copy=product.querySelector('.app-appbar-copy'); add(copy,'v-appbar__copy');
  add(copy?.querySelector('h3'),'v-appbar__title'); add(copy?.querySelector('span'),'v-appbar__subtitle');
  const content=product.querySelector('.app-content'); add(content,'v-template__scroll');
  if(content){ content.dataset.withAppbar='true'; if(product.querySelector('.app-actions')) content.dataset.withFooter='true'; }
  const body=product.querySelector('.body-stack'); add(body,'v-stack');
  // Page templates own the scroll geometry. Non-form screens use VPage for the canonical 16px mobile edge;
  // Form/Wizard templates already carry their own 16px scroll padding. Never apply both layers.
  if(body){
    if(['form','wizard','state'].includes(template)) body.classList.remove('v-page');
    else add(body,'v-page');
  }
  const footer=product.querySelector('.app-actions');
  if(footer){ add(footer,'v-sticky-footer'); canonical(footer,'DS v2 / Sticky Footer'); const buttons=footer.querySelectorAll(':scope > button'); const n=buttons.length; footer.dataset.layout=n>1?'dual':'single'; if(n===1) buttons[0].style.width='100%'; }
}
function normalizeButtons(root){
  qsa(root,'[data-ds-component="VButton"],button.button,button.ds24-button').forEach(el=>{
    add(el,'v-btn'); canonical(el,'VButton'); el.dataset.hierarchy=buttonHierarchy(el); el.dataset.size=text(el.dataset.dsPropSize).includes('small')?'small':text(el.dataset.dsPropSize).includes('large')?'large':'default';
    if(el.disabled) el.dataset.state='disabled'; if(text(el.dataset.dsPropFullWidth)==='true'||el.classList.contains('button--full')) el.dataset.width='fill';
  });
  qsa(root,'[data-ds-component="DS v2 / Link"]').forEach(el=>{add(el,'v-link');canonical(el,'DS v2 / Link');});
  qsa(root,'[data-ds-component="DS v2 / Icon Button"]').forEach(el=>{add(el,'v-icon-btn');canonical(el,'DS v2 / Icon Button');});
  qsa(root,'[data-ds-component="VQuickActionButton"]').forEach(el=>{add(el,'v-btn');canonical(el,'VButton');el.dataset.hierarchy='secondary';});
}
function normalizeFields(root){
  const kinds={VTextField:'text',VTextarea:'textarea',VNumberField:'text',VMoneyField:'money',VSelect:'select',VDateField:'date',VDatePickerField:'date',VDatePicker:'date'};
  Object.entries(kinds).forEach(([name,kind])=>qsa(root,`[data-ds-component="${name}"]`).forEach(el=>{
    const field=el.matches('input,select,textarea')?el.closest('label,div')||el:el;
    add(field,'v-field'); canonical(field,name==='VNumberField'?'VTextField':name==='VDateField'||name==='VDatePickerField'?'VDatePicker':name); field.dataset.kind=kind; const st=stateFrom(field); if(st!=='default') field.dataset.state=st;
    const control=field.matches('input,select,textarea')?field:field.querySelector('input,select,textarea');
    add(control,'v-control');
    const label=field.querySelector(':scope > label,:scope > span:first-child'); if(label&&!label.matches('input,select,textarea')) add(label,'v-field__label');
    const helper=field.querySelector('.helper-text,.field-helper,.field-error'); if(helper) add(helper,'v-helper');
  }));
  qsa(root,'[data-ds-component="VField"]').forEach(el=>{ const c=el.querySelector('select,textarea,input'); if(!c)return; add(el,'v-field'); const kind=c.matches('select')?'select':c.matches('textarea')?'textarea':'text'; el.dataset.kind=kind; canonical(el,kind==='select'?'VSelect':kind==='textarea'?'VTextarea':'VTextField'); add(c,'v-control'); const lab=el.querySelector(':scope > span:first-child,:scope > label'); if(lab)add(lab,'v-field__label'); const help=el.querySelector('small,.helper-text');if(help)add(help,'v-helper'); });
  qsa(root,'[data-ds-component="VSearchBar"],.ds24-search').forEach(el=>{
    const search=el.matches('input')?el.parentElement:el; add(search,'v-search'); canonical(search,'VSearchBar'); const input=search.querySelector('input'); add(input,'v-control');
    const icon=search.querySelector('[data-ds-component="VIcon"],svg.icon,[data-v-icon]'); if(icon) add(icon,'v-search__leading');
  });
  qsa(root,'[data-ds-component="VRadio"],.v364-radio-option,.val14-choice-row,.ac310-radio-row').forEach(el=>{
    add(el,'v-checkrow'); canonical(el,'VRadio'); el.dataset.kind='radio'; const st=stateFrom(el); el.dataset.state=(st==='selected'?'on':st==='disabled'?'disabled-off':'off');
    const c=el.querySelector('.v364-radio-control,.val14-radio-control,.ac310-radio-control,.io06-radio,.v-radio'); add(c,'v-radio');
  });
  qsa(root,'[data-ds-component="VCheckbox"]').forEach(el=>{add(el,'v-checkrow');canonical(el,'VCheckbox');el.dataset.kind='checkbox';el.dataset.state=stateFrom(el)==='selected'?'on':'off';const c=el.querySelector('.checkbox-control,.v-checkbox');add(c,'v-checkbox');});
  qsa(root,'[data-ds-component="VSegmentedControl"]').forEach(el=>{add(el,'v-segmented');canonical(el,'VSegmentedControl');});
  qsa(root,'[data-ds-component="VSegmentedControlItem"]').forEach(el=>{add(el,'v-segmented__item');el.dataset.selected=String(stateFrom(el)==='selected'||text(el.dataset.dsPropSelected)==='true');canonical(el,'VSegmentedControl');});
}
function normalizeDisplay(root){
  qsa(root,'[data-ds-component="VBadge"],.status-badge,.ds24-badge').forEach(el=>{add(el,'v-badge');canonical(el,'VBadge');el.dataset.tone=toneFrom(el);});
  qsa(root,'[data-ds-component="VChip"],.ds24-chip').forEach(el=>{add(el,'v-chip');canonical(el,'VChip');el.dataset.tone=(stateFrom(el)==='selected'?'brand':toneFrom(el,'neutral')); if(el.disabled) el.dataset.state='disabled';});
  qsa(root,'[data-ds-component="DS v2 / List Row"],.ds24-list-row,.bj02-ds-list-row').forEach(el=>{
    add(el,'v-list-row'); canonical(el,'DS v2 / List Row'); el.dataset.density=text(el.dataset.dsPropDensity).includes('compact')?'compact':'default'; const rowType=text(el.dataset.dsPropType); el.dataset.type=rowType.includes('selection')?'selection':rowType.includes('status')?'status':'navigation'; if(el.classList.contains('bj02-review-summary-row'))el.dataset.density='default'; const st=stateFrom(el); if(st!=='default')el.dataset.state=st;
    const copy=el.querySelector('.ds24-list-row__copy,.bj02-ds-list-copy,.bj02-review-summary-copy,.io-product-copy,.v-list-row__copy,.v-grow'); add(copy,'v-list-row__copy');
    const title=copy?.querySelector('strong,.ds24-list-row__title,.v-list-row__title'); add(title,'v-list-row__title','v-truncate'); if(title&&!title.title) title.title=title.textContent.trim(); const support=copy?.querySelector('small,span:not(.v-list-row__title),.ds24-list-row__support,.v-list-row__support'); add(support,'v-list-row__support','v-truncate'); if(support&&!support.title) support.title=support.textContent.trim();
  });
  qsa(root,'[data-ds-component="DS v2 / Info Row"],.ds24-info-row,.bj02-info-row,.io-meta-row').forEach(el=>{add(el,'v-info-row');canonical(el,'DS v2 / Info Row'); const kids=Array.from(el.children); add(kids[0],'v-info-row__label'); add(kids[kids.length-1],'v-info-row__value');});
  qsa(root,'[data-ds-component="DS v2 / Key-value Row"],.ds24-key-value-row,.bj02-key-value-row').forEach(el=>{add(el,'v-kv-row');canonical(el,'DS v2 / Key-value Row'); const kids=Array.from(el.children); add(kids[0],'v-kv-row__key'); add(kids[kids.length-1],'v-kv-row__value'); if(text(el.dataset.dsPropState).includes('emphasis')||el.classList.contains('is-emphasis')||el.classList.contains('ds24-key-value-row--emphasis'))el.dataset.state='emphasis';});
  qsa(root,'[data-ds-component="DS v2 / Record Card"]').forEach(el=>{add(el,'v-record-card');canonical(el,'DS v2 / Record Card');});
  qsa(root,'[data-ds-component="DS v2 / Summary Card"],.ds24-summary-card').forEach(el=>{add(el,'v-summary-card','v-card');canonical(el,'DS v2 / Summary Card');add(el.querySelector('.ds24-summary-card__title'),'v-summary-card__title');add(el.querySelector('.ds24-summary-card__body'),'v-summary-card__body');});
  qsa(root,'[data-ds-component="DS v2 / Metric Card"],.ac310-metric').forEach(el=>{add(el,'v-metric-card','v-card');canonical(el,'DS v2 / Metric Card'); const val=el.querySelector('strong,.value'); add(val,'v-metric-card__value');});
  qsa(root,'[data-ds-component="DS v2 / Audit Item"],.ac310-audit-item').forEach(el=>{add(el,'v-audit-item');canonical(el,'DS v2 / Audit Item');add(el.querySelector('.ac310-audit-item__copy'),'v-audit-item__copy');});
  qsa(root,'[data-ds-component="DS v2 / Timeline Item"],.timeline-item').forEach(el=>{add(el,'v-timeline-item');canonical(el,'DS v2 / Timeline Item'); const marker=el.querySelector('.timeline-marker'); if(marker){add(marker,'v-timeline-item__rail'); if(!marker.querySelector('.v-timeline-item__dot')) marker.innerHTML='<span class="v-timeline-item__dot"></span><span class="v-timeline-item__line"></span>';}});
  qsa(root,'[data-ds-component="VSection"]').forEach(el=>{add(el,'v-section');canonical(el,'VSection composition');});
  qsa(root,'.bj02-section-heading,.ds24-section-title,.compact-section-heading,.io-section-title,.ac310-surface__head,.review-card-header,.lot-section-heading').forEach(el=>{add(el,'v-row');const intro=el.firstElementChild;if(intro&&intro.tagName==='DIV')add(intro,'v-stack-2','v-grow');const strong=el.querySelector('strong');if(strong)add(strong,'v-h4');const support=el.querySelector('span');if(support)add(support,'v-caption','v-muted');});
  qsa(root,'[data-ds-component="VPageScaffold"]').forEach(el=>add(el,'v-page-scaffold'));
  qsa(root,'[data-ds-component="VPagePadding"]').forEach(el=>{
    if(el.classList.contains('v-template__scroll')) el.classList.remove('v-page-padding');
    else { add(el,'v-page-padding'); canonical(el,'Layout/Mobile edge foundation'); }
  });
  qsa(root,'[data-ds-component="VIconBox"],.icon-box').forEach(el=>{add(el,'v-icon-box');canonical(el,'VIconBox foundation primitive');});
  qsa(root,'[data-ds-component="VText"]').forEach(el=>{const c=el.matches('h1,h2')?'v-h2':el.matches('h3')?'v-h3':el.matches('h4,strong')?'v-label':el.matches('small')?'v-caption':'v-body';add(el,c);canonical(el,'Typography foundation');});
  qsa(root,'[data-ds-component="DS v2 / List Top Bar"]').forEach(el=>{add(el,'v-list-topbar');canonical(el,'DS v2 / List Top Bar');});
  qsa(root,'[data-ds-component="DS v2 / Readiness Item"]').forEach(el=>{add(el,'v-readiness');canonical(el,'DS v2 / Readiness Item');});
  qsa(root,'[data-ds-component="DS v2 / Search Results Dropdown"]').forEach(el=>{add(el,'v-search-results');canonical(el,'DS v2 / Search Results Dropdown');});
  qsa(root,'[data-ds-component="DS v2 / Search & Filter Header"]').forEach(el=>{add(el,'v-search-filter-header');canonical(el,'DS v2 / Search & Filter Header');});
  qsa(root,'[data-ds-component="VAppBar"]').forEach(el=>{add(el,'v-appbar');canonical(el,'VAppBar');});
  qsa(root,'[data-ds-component="VAppBarTitle"]').forEach(el=>{add(el,'v-appbar__title');canonical(el,'VAppBar');});
  qsa(root,'[data-ds-component="VAppBarSubtitle"]').forEach(el=>{add(el,'v-appbar__subtitle');canonical(el,'VAppBar');});
  qsa(root,'[data-ds-component="VCardIcon"]').forEach(el=>add(el,'v-card-icon'));
  qsa(root,'[data-ds-component="VCardTitle"]').forEach(el=>add(el,'v-card-title'));
}
function normalizeFeedback(root){
  qsa(root,'[data-ds-component="VBanner"],.v-banner').forEach(el=>{add(el,'v-banner');canonical(el,'VBanner');el.dataset.tone=toneFrom(el,'info');el.dataset.density=text(el.dataset.dsPropDensity).includes('compact')?'compact':'default';const copy=el.querySelector('.v-banner-copy,.v-banner__copy');add(copy,'v-banner__copy');add(copy?.querySelector('strong'),'v-banner__title');add(copy?.querySelector('span'),'v-banner__message');});
  qsa(root,'[data-ds-component="VEmptyState"],.empty-state').forEach(el=>{add(el,'v-empty-state');canonical(el,'VEmptyState');add(el.querySelector('[data-ds-component="VEmptyMedia"],.icon-box'),'v-empty-state__icon');add(el.querySelector('[data-ds-component="VEmptyTitle"],h3'),'v-empty-state__title');add(el.querySelector('[data-ds-component="VEmptyDescription"],p'),'v-empty-state__description');});
  qsa(root,'[data-ds-component="VLoading"],.v-loading-spinner').forEach(el=>{add(el,'v-loading');canonical(el,'VLoading');el.dataset.size=el.dataset.size||'24';});
  qsa(root,'[data-ds-component="VFileDropZone"],.file-drop-zone').forEach(el=>{add(el,'v-dropzone');canonical(el,'VFileDropZone'); add(el.querySelector('.file-drop-copy strong'),'v-dropzone__title');add(el.querySelector('.file-drop-copy span'),'v-dropzone__support');});
  qsa(root,'[data-ds-component="VSkeleton"]').forEach(el=>{add(el,'v-skeleton');canonical(el,'VSkeleton');if(!el.dataset.type)el.dataset.type='line';});
  qsa(root,'[data-ds-component="VProgress"]').forEach(el=>{add(el,'v-progress');canonical(el,'VProgress');if(!el.dataset.type)el.dataset.type='linear';});
  qsa(root,'[data-ds-component="VToast"]').forEach(el=>{add(el,'v-toast');canonical(el,'VToast');});
}
function normalizeSurfaces(root){
  // Theme-specific information groupings are composition only. Do not invent a VCard skin.
  qsa(root,'.ds24-info-group,.review-card,.io-read-card,.ac310-surface,.ac310-list-surface,.cr-fact-card,.bj05-section,.io06-section,.bj02-review-section').forEach(el=>{
    if(el.classList.contains('v-list-row')||el.classList.contains('v-banner')) return;
    if(el.dataset.dsCanonicalComponent&&el.dataset.dsCanonicalComponent!=='VSection composition') return;
    add(el,'v-section'); canonical(el,'VSection composition');
    const head=el.querySelector(':scope > .ds24-info-group__title,:scope > .review-card-header,:scope > .ac310-surface__head,:scope > .bj02-section-heading');
    if(head){add(head,'v-row'); const title=head.querySelector('strong');if(title)add(title,'v-h4'); const copy=head.firstElementChild;if(copy&&copy.tagName==='DIV')add(copy,'v-stack-2','v-grow');}
    const body=el.querySelector(':scope > .ds24-info-group__rows,:scope > .review-card-body,:scope > .ac310-info-rows'); if(body)add(body,'v-stack-2');
  });
  qsa(root,'.ds24-list-stack,.receipt-line-list,.bj02-record-stack,.bj02-review-products,.io-product-list,.ac310-list-stack,.ac310-form-stack,.form-stack,.quick-source-form,.v430-list,.v430-flat__rows,.ac310-audit-list,.val14-choice-list,.v460-key-stack,.v430-key-stack').forEach(el=>add(el,'v-stack-2'));
  qsa(root,'.ds24-info-stack,.bj02-info-stack,.io06-result-rows,.ac310-info-rows,.ac310-key-value-stack').forEach(el=>add(el,'v-stack-2'));
  qsa(root,'.sheet-actions,.approval-actions').forEach(el=>add(el,'v-row'));
  qsa(root,'.result-hero,.io-result').forEach(el=>add(el,'v-section'));
}

function normalizeOverlays(root){
  qsa(root,'.sheet-backdrop,.confirm-backdrop,.bottom-sheet-backdrop').forEach(el=>{add(el,'v-overlay');el.dataset.placement='bottom';});
  qsa(root,'[data-ds-component="VBottomSheet"],.bottom-sheet').forEach(el=>{add(el,'v-bottom-sheet');canonical(el,'VBottomSheet');add(el.querySelector('.sheet-handle,.bottom-sheet-handle'),'v-bottom-sheet__handle');add(el.querySelector('.sheet-title h3,.sheet-title,.bottom-sheet-title'),'v-bottom-sheet__title');add(el.querySelector('.sheet-content,.bottom-sheet-content'),'v-bottom-sheet__content');});
  qsa(root,'[data-ds-component="DS v2 / Confirmation Sheet"],.confirm-dialog').forEach(el=>{add(el,'v-confirmation-sheet');canonical(el,'DS v2 / Confirmation Sheet');const h=el.querySelector('h2,h3');add(h,'v-h3');const p=el.querySelector('p');add(p,'v-body','v-muted');add(el.querySelector('.confirm-dialog-actions'),'v-confirmation-sheet__actions');});
  qsa(root,'[data-ds-component="DS v2 / Select Sheet"]').forEach(el=>{add(el,'v-select-sheet');canonical(el,'DS v2 / Select Sheet');});
  qsa(root,'[data-ds-component="DS v2 / Form Sheet"]').forEach(el=>{add(el,'v-form-sheet');canonical(el,'DS v2 / Form Sheet');});
  qsa(root,'[data-ds-component="VNumericKeypadSheet"]').forEach(el=>{add(el,'v-numeric-keypad');canonical(el,'VNumericKeypadSheet');});
}
function normalizeCanonicalPatterns(root){
  qsa(root,'[data-ds-component="DS v2 / Sticky Footer"],.app-actions').forEach(el=>{add(el,'v-sticky-footer');canonical(el,'DS v2 / Sticky Footer');});
  qsa(root,'[data-ds-component="DS v2 / Form Sheet"]').forEach(el=>{add(el,'v-form-sheet');canonical(el,'DS v2 / Form Sheet');});
  qsa(root,'[data-ds-component="DS v2 / Search Results Dropdown"]').forEach(el=>{add(el,'v-search-results');canonical(el,'DS v2 / Search Results Dropdown');});
}
function normalizeIcons(root){ qsa(root,'[data-ds-component="VIcon"]:not([data-v-icon])').forEach(normalizeIcon); }

export function alignTheme7ToDs16(root=document){
  const product=root.matches?.('[data-mobile-product]')?root:root.querySelector?.('[data-mobile-product]'); if(!product) return;
  normalizeShell(product); normalizeButtons(product); normalizeFields(product); normalizeDisplay(product); normalizeFeedback(product); normalizeSurfaces(product); normalizeOverlays(product); normalizeCanonicalPatterns(product); normalizeIcons(product);
  if(product.dataset.vet45DsInitialized!=='true'){ initVet45DS(product); product.dataset.vet45DsInitialized='true'; }
}
window.alignVet45Ds16=alignTheme7ToDs16;

const host=document.getElementById('app-screen');
if(host){
  const run=()=>alignTheme7ToDs16(host);
  new MutationObserver(()=>queueMicrotask(run)).observe(host,{childList:true,subtree:true});
  run();
}
