/* shared-valuation.js — helpers dùng chung cụm giá trị BJ-03 / 13 / 14 (T7-P A5). */
function valuationDsTone(tone){const t=String(tone||"Neutral").toLowerCase();return ({success:"Success",warning:"Warning",danger:"Danger",error:"Danger",info:"Info",neutral:"Neutral",brand:"Brand"})[t]||"Neutral";}
function valuationProductHeader({name,code,uom,status="",tone="Neutral",value="",meta=""}){
  const trailing=value?`<span class="valuation-product-value"><small>Giá trị</small><strong>${esc(value)}</strong></span>`:(status?ds24Badge(status,valuationDsTone(tone)):"");
  const subtitle=`${code} · ${uom}${meta?` · ${meta}`:""}`;
  return ds24ListRow({title:name,subtitle,trailing,leading:"package",attrs:'data-layout-role="valuation-product-header" data-ds-role="valuation-product-summary"',type:"Status",density:"Compact",interactive:false});
}
function valuationReadOnlyChild({title,subtitle,trailing=""}){
  return `<div class="valuation-readonly-child" data-composed-from="VText"><span class="valuation-child-branch" aria-hidden="true"></span><span class="valuation-child-copy"><strong>${esc(title)}</strong><small>${esc(subtitle)}</small></span>${trailing?`<span class="valuation-child-trailing">${trailing}</span>`:""}</div>`;
}

function ensureVal03ReviewFixture(){
    if(activeFlowId!=="UIF-03"||activeScreenId!=="SCR-017"||stateByScreen[activeScreenId]!=="READY") return;
    if(val03SelectedSlices().length>0 && val03ScopeReady()) { if(val03ReviewSourceVersion==null) val03ReviewSourceVersion=val03Current().sourceVersion; return; }
    const r=val03Current();
    r.groups.forEach(g=>g.slices.forEach(s=>{s.selected=false;}));
    const g=r.groups.find(x=>x.id==="VAL03-G1")||r.groups.find(x=>val03EvidenceState(x)==="READY");
    const s=g?.slices.find(x=>x.pendingQty>0);
    if(g&&s){s.selected=true;s.selectedQty=s.pendingQty;if(!g.selectedSource)g.selectedSource=g.sources[0]?.id||"";val03ReviewSourceVersion=r.sourceVersion;}
  }

function ensureVal03ResultFixture(){
    if(activeFlowId!=="UIF-03"||activeScreenId!=="SCR-019"||stateByScreen[activeScreenId]!=="COMPLETED"||val03LastResult) return;
    const r=val03Current();
    r.groups.forEach(g=>g.slices.forEach(sl=>{sl.selected=false;}));
    const g=r.groups.find(x=>x.id==="VAL03-G1")||r.groups.find(x=>val03EvidenceState(x)==="READY");
    const sl=g?.slices.find(x=>x.pendingQty>0);
    if(g&&sl){sl.selected=true;sl.selectedQty=sl.pendingQty;if(!g.selectedSource)g.selectedSource=g.sources[0]?.id||"";val03ReviewSourceVersion=r.sourceVersion;val03Commit();}
  }
