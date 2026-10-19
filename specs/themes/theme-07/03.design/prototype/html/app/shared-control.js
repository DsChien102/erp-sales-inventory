/* shared-control.js — helpers dùng chung cụm kiểm soát BJ-08/09/10/11/12/15/16/17 (T7-P A7–A10).
 * A7: ac310Tone / CleanText / SanitizeMarkup / Return / InfoSurface / RecordRow.
 * A8: SectionTitle / KeyValueSurface / ListSurface / RadioSurface / Audit* / SummaryMetrics / Field / ApprovalFooter.
 * A9: cfMoney…cfSecondary, ac310ProductRow.
 * A10: crFactCard, ac321CanonicalChips.
 * A11: icCard/icField/icTextarea/icHeaderRows/icSecondary/icApprovalButtons.
 */
function ac310Tone(tone="Neutral") {
  const map={success:"Success",warning:"Warning",danger:"Danger",error:"Danger",info:"Info",neutral:"Neutral",brand:"Brand"};
  return map[String(tone).toLowerCase()] || tone;
}
function ac310CleanText(text) {
  let out=String(text??"");
  const replacements=[
    [/\bauthoritative\b/gi,"chính thức"],
    [/\bDOM\b/g,"giao diện"],
    [/\bguard\b/gi,"điều kiện kiểm soát"],
    [/\bledger\b/gi,"sổ kho"],
    [/\brecovery\b/gi,"khôi phục"],
    [/\bcommit\b/gi,"ghi nhận"],
    [/\bUNKNOWN\b/g,"chưa xác định"],
    [/\bCut[- ]?off\b/gi,"Thời điểm chốt"],
    [/\bLOT\b/g,"Lô"],
    [/\bUOM\b/g,"Đơn vị"],
    [/\bblocker\b/gi,"điều kiện chưa đạt"],
    [/\bdependency\b/gi,"nghiệp vụ phụ thuộc"],
    [/\bprojection\b/gi,"số liệu hiển thị"],
    [/\bfinality\b/gi,"kết quả chính thức"]
  ];
  replacements.forEach(([re,val])=>{out=out.replace(re,val);});
  return out;
}
function ac310SanitizeMarkup(html) {
  const template=document.createElement("template");
  template.innerHTML=String(html||"");
  const walker=document.createTreeWalker(template.content,NodeFilter.SHOW_TEXT);
  const nodes=[]; while(walker.nextNode()) nodes.push(walker.currentNode);
  nodes.forEach((node)=>{node.nodeValue=ac310CleanText(node.nodeValue);});
  return template.innerHTML;
}
function ac310Return(html){return ac310SanitizeMarkup(html);}
function ac310InfoSurface(title,rows,{extraClass="",badge="",badgeTone="Neutral"}={}){
  const head=title?`<div class="ac310-surface__head"><h2>${esc(title)}</h2>${badge?ds24Badge(badge,ac310Tone(badgeTone)):""}</div>`:"";
  const body=(rows||[]).map((r)=>ds24InfoRow(r[0],r[1],r[2]?"ac310-info-row--emphasis":"")).join("");
  return `<section class="ac310-surface ${extraClass}" data-layout-pattern="Grouped surface" data-composed-from="DS v2 / Info Row${badge?',VBadge':''}">${head}<div class="ac310-info-rows">${body}</div></section>`;
}
function ac310RecordRow({title,subtitle="",badge="",tone="Neutral",attrs="",leading=null,status=false,disabled=false,extraClass=""}){
  return ds24ListRow({title,subtitle,trailing:badge?ds24Badge(badge,ac310Tone(tone)):"",leading,attrs,type:status?"Status":"Navigation",density:status?"Compact":"Default",interactive:!status,disabled,extraClass:`ac310-record-row ${extraClass}`.trim()});
}

function ac310SectionTitle(title,meta=""){
  return `<div class="ac310-section-title" data-ds-component="VText"><h2>${esc(title)}</h2>${meta?`<span>${esc(meta)}</span>`:""}</div>`;
}
function ac310KeyValueSurface(title,rows,{extraClass=""}={}){
  const head=title?`<div class="ac310-surface__head"><h2>${esc(title)}</h2></div>`:"";
  return `<section class="ac310-surface ${extraClass}" data-layout-pattern="Grouped surface" data-composed-from="DS v2 / Key-value Row">${head}<div class="ac310-key-value-stack">${(rows||[]).map((r)=>ds24KeyValueRow(r[0],r[1],!!r[2])).join("")}</div></section>`;
}
function ac310ListSurface(rows,extra=""){
  return ds24GroupedCollection(`<div class="ac310-list-stack">${rows}</div>`,`ac310-list-surface ${extra}`,"DS v2 / List Row,VBadge");
}
function ac310RadioSurface(title,choices){
  return `<section class="ac310-surface ac310-radio-surface" data-composed-from="VText,VRadio">${title?`<div class="ac310-surface__head"><h2>${esc(title)}</h2></div>`:""}<div class="ac310-radio-list">${choices.join("")}</div></section>`;
}
function ac310AuditItem(type,title,meta){
  const t=String(type||"System");
  const iconName=t==="Create"?"checkCircle":t==="Update"?"edit":t==="Delete"?"alert":"info";
  return `<div class="ac310-audit-item ac310-audit-item--${t.toLowerCase()}" data-ds-component="DS v2 / Audit Item" data-figma-node="525:621" data-ds-prop-type="${t}">${icon(iconName,"ac310-audit-item__icon")}<span class="ac310-audit-item__copy"><strong>${esc(title)}</strong><small>${esc(meta)}</small></span></div>`;
}
function ac310AuditSurface(title,items){
  return `<section class="ac310-audit-surface" data-composed-from="DS v2 / Audit Item">${title?ac310SectionTitle(title):""}<div class="ac310-audit-list">${items.join("")}</div></section>`;
}
function ac310SummaryMetrics(items){
  return `<section class="ac310-metrics" data-composed-from="DS v2 / Metric Card">${items.map(([label,value])=>`<div class="ac310-metric" data-ds-component="DS v2 / Metric Card" data-figma-node="525:382"><span>${esc(label)}</span><strong>${esc(String(value))}</strong></div>`).join("")}</section>`;
}
function ac310Field(label,value,attrs="",helper="",type="text"){
  const component=type==="number"?"VNumberField":type==="date"?"VDateField":"VTextField";
  return `<label class="ac310-field" data-ds-component="${component}"><span>${esc(label)}</span><input type="${type}" value="${escapeAttribute(value)}" ${attrs}>${helper?`<small>${esc(helper)}</small>`:""}</label>`;
}
function ac310ApprovalFooter(rejectAttr,approveAttr,approveLabel="Duyệt"){
  // Dual footer nguy hiểm (trước A8 do v361 normalizeDualFooters thêm lúc chạy): Từ chối | Duyệt trên một hàng.
  return `<footer class="app-actions figma-sticky-footer ac310-two-actions v361-dual-footer v361-dual-footer--danger" data-ds-pattern="Sticky Footer" data-ds-prop-layout="Dual" data-ds-prop-tone="Danger"><button class="button button--secondary" type="button" ${rejectAttr} data-ds-component="VButton" data-ds-prop-tone="VComponentTone.danger" data-ds-profile="button.destructiveSecondary">Từ chối</button><button class="button button--primary" type="button" ${approveAttr} data-ds-component="VButton">${esc(approveLabel)}</button></footer>`;
}

function ac310ProductRow({name,code,meta="",badge="",tone="Neutral",attrs="",status=false}){
  const subtitle=[code,meta].filter(Boolean).join(" · ");
  return ds24ListRow({title:name,subtitle,trailing:badge?ds24Badge(badge,ac310Tone(tone)):"",leading:"package",attrs,type:status?"Status":"Navigation",density:status?"Compact":"Default",interactive:!status,extraClass:"ac310-product-row"});
}

/* cf* — BJ-12 / BJ-15 (T7-P A9) */
const cfMoney = (n) => `${Number(n || 0).toLocaleString("vi-VN")} ₫`;
const cfMoneyInput = (n) => n === "" || n == null ? "" : Number(String(n).replace(/[^0-9-]/g, "") || 0).toLocaleString("vi-VN");
const cfNumber = (n) => Number(n || 0).toLocaleString("vi-VN");
function cfDateVN(value){const v=String(value||"");const m=v.match(/^(\d{4})-(\d{2})-(\d{2})$/);return m?`${m[3]}/${m[2]}/${m[1]}`:v;}
function cfDateKey(value){const v=String(value||"");const m=v.match(/^(\d{2})\/(\d{2})\/(\d{4})$/);return m?`${m[3]}-${m[2]}-${m[1]}`:v;}
function cfField(label,value,attr,type="text",hint=""){
  const isDate=type==="date", isMoney=type==="money", htmlType=(isDate||isMoney)?"text":type, shown=isDate?cfDateVN(value):isMoney?cfMoneyInput(value):value;
  const extra=isDate?' inputmode="numeric" placeholder="dd/mm/yyyy"':isMoney?' inputmode="numeric"':"";
  const component=isDate?"VDatePickerField":isMoney?"VMoneyField":type==="number"?"VNumberField":"VTextField";
  const figmaNode=isMoney?' data-figma-node="522:7322"':'';
  const stateAttr=isMoney?` data-ds-prop-state="${shown!==""?"Filled":"Default"}"`:"";
  const moneySuffix=isMoney?'<span class="money-suffix" aria-hidden="true">₫</span>':"";
  return `<div class="form-field cf-field" data-ds-component="${component}"${figmaNode}${stateAttr}><label>${label}</label><div class="input-shell"><input type="${htmlType}" value="${escapeAttribute(shown)}" ${attr}${extra}>${moneySuffix}</div>${hint?`<small class="field-help">${hint}</small>`:""}</div>`;
}
function cfSelect(label,value,options,attr,hint=""){
  return `<div class="form-field cf-field" data-ds-component="VSelect"><label>${label}</label><div class="input-shell"><select ${attr}>${options.map(([v,l])=>`<option value="${escapeAttribute(v)}" ${String(v)===String(value)?"selected":""}>${l}</option>`).join("")}</select><span>${icon("chevronDown","icon--sm")}</span></div>${hint?`<small class="field-help">${hint}</small>`:""}</div>`;
}
function cfSummaryGrid(items){return `<div class="cf-summary-grid">${items.map(([l,v])=>`<div class="cf-summary-tile"><small>${l}</small><strong>${v}</strong></div>`).join("")}</div>`;}
function cfSecondary(label,attr,tone="neutral"){return `<button class="button button--secondary cf-secondary" type="button" ${attr} data-ds-component="VButton" data-ds-prop-variant="VButtonVariant.secondary" data-ds-prop-size="VButtonSize.medium" data-ds-prop-tone="VComponentTone.${tone}">${label}</button>`;}

function crFactCard(title,rows,badge="",tone="info"){const calibrated=FIGMA_MIGRATED_FLOWS.has(activeFlowId);return `<section class="review-card cr-fact-card" data-ds-component="${calibrated?'VSection':'VCard'}" ${calibrated?'data-composed-from="VText,VBadge,DS v2 / Info Row"':'data-ds-profile="card.readOnly"'}><div class="review-card-header"><strong data-ds-component="VText">${title}</strong>${badge?vBadge(badge,tone):""}</div><div class="review-card-body">${rows.map(r=>ioMetaRow(r[0],r[1],!!r[2])).join("")}</div></section>`;}
function ac321CanonicalChips(active,items,attr){return `<div class="ac321-chip-wrap" data-composed-from="VChip" aria-label="Bộ lọc">${items.map(([key,label])=>ds24Chip(key,label,active===key,attr)).join('')}</div>`;}

/* ic* — shared Inventory Control helpers (was duplicated in core.js + bj09.js; T7-P A11). */
function icCard(title,body){const calibrated=FIGMA_MIGRATED_FLOWS.has(activeFlowId);return `<section class="review-card" data-ds-component="${calibrated?'VSection':'VCard'}" ${calibrated?'data-composed-from="VText,DS v2 / Info Row,VTextField"':'data-ds-profile="card.readOnly"'}><div class="review-card-header"><strong>${title}</strong></div><div class="review-card-body">${body}</div></section>`;}
function icField(label,value,attr="",type="text",hint=""){return `<div class="form-field" data-ds-component="${type==='number'?'VNumberField':'VTextField'}"><label>${label}</label><div class="input-shell"><input type="${type}" value="${escapeAttribute(value)}" ${attr}></div>${hint?`<small class="helper-text">${hint}</small>`:""}</div>`;}
function icTextarea(label,value,attr="",placeholder=""){return `<div class="form-field ic-textarea-field" data-ds-component="VTextarea" data-figma-node="522:7212"><label>${label}</label><textarea class="textarea" ${attr} placeholder="${escapeAttribute(placeholder)}">${esc(value)}</textarea></div>`;}
function icHeaderRows(rows){return ioReadCard(rows.map(([a,b,strong])=>ioMetaRow(a,b,!!strong)).join(''));}
function icSecondary(label,action,tone="secondary"){const c=tone==='danger'?'button button--danger button--full':'button button--secondary button--full';return `<button class="${c}" type="button" ${action}>${label}</button>`;}
function icApprovalButtons(prefix){return `<div class="ic-action-stack">${icSecondary("Từ chối",`data-${prefix}-action="reject"`,'danger')}${primaryFooter("Duyệt",`data-${prefix}-action="approve"`)}</div>`;}
