/* BJ-01 — Theo dõi tồn, khả dụng và chỉ báo vận hành (UIF-01). Màn: SCR-001 Tồn kho, SCR-003 Chi tiết tồn kho
 * (SCR-004 = SCR-003 với sheet lô đang mở).
 *
 * Đã viết lại sạch (T7-P bước A, 2026-10-16): mọi hàm dựng, fixture và xử lý sự kiện của BJ-01 nằm ở đây; màn dựng
 * thẳng (ownedFlows), không qua bước sửa sau dựng legacy. Sửa BJ-01: sửa thẳng file này.
 * Dùng chung từ app/core.js: appShell, ds24* (ListRow, Badge, DotBadge, Chip, Search, KeyValueRow, InfoRow, Sheet,
 * SectionTitle), vBanner, deniedBody, loadingBody, icon, esc, escapeAttribute, navigate, render, renderAppScreen.
 * bj01Empty cũng đang được BJ-08 (legacy trong core.js) gọi.
 */

// ---- Fixture và trạng thái màn
const bj01Products = [
  { id:"INV-NOB", name:"Nobivac DHPPi", code:"SP-000184", barcode:"8938500001012", stockUom:"hộp", tracking:"LOT", physical:120, eligible:118, reserved:12, available:106, threshold:30, target:80, monitoringConfigStatus:"CONFIGURED", eligibilityBreakdown:[{reason:"Cách ly",quantity:2}], latestPhysicalMovement:{label:"Nhận hàng",source:"PN-260816-04",delta:118}, reservationSummary:{quantity:12,source:"SO-260817-08"}, lots:[
    { code:"DH2507", expiryDisplay:"30/11/2026", expiryPrecision:"DAY", physical:70, eligible:70, stockState:"SELLABLE", expiryIndicator:"NONE", nearExpiryAction:null },
    { code:"DH2509", expiryDisplay:"15/09/2026", expiryPrecision:"DAY", physical:50, eligible:48, stockState:"SELLABLE", expiryIndicator:"NEAR_EXPIRY", nearExpiryAction:"WARN", daysToExpiry:19 },
  ]},
  { id:"INV-AMX", name:"Amox 500", code:"SP-000066", barcode:"8938500004068", stockUom:"hộp", tracking:"NONE", physical:48, eligible:47, reserved:5, available:42, threshold:50, target:80, monitoringConfigStatus:"CONFIGURED", eligibilityBreakdown:[{reason:"Cách ly",quantity:1}], latestPhysicalMovement:{label:"Nhận hàng",source:"PN-260825-02",delta:48}, reservationSummary:{quantity:5,source:"SO-260827-18"}, lots:[] },
  { id:"INV-ENRO", name:"Enrofloxacin 10%", code:"SP-000091", barcode:"8938500005096", stockUom:"chai", tracking:"NONE", physical:0, eligible:0, reserved:0, available:0, threshold:10, target:30, monitoringConfigStatus:"CONFIGURED", eligibilityBreakdown:[], latestPhysicalMovement:{label:"Xuất bán",source:"SO-260826-11",delta:-6}, reservationSummary:{quantity:0,source:null}, lots:[] },
  { id:"INV-TYLO", name:"Tylosin 20%", code:"SP-000122", barcode:"8938500006123", stockUom:"lọ", tracking:"LOT", physical:18, eligible:7, reserved:3, available:4, threshold:8, target:24, monitoringConfigStatus:"CONFIGURED", eligibilityBreakdown:[{reason:"Hết hạn",quantity:11}], latestPhysicalMovement:{label:"Nhận hàng",source:"PN-260701-07",delta:18}, reservationSummary:{quantity:3,source:"SO-260826-09"}, lots:[
    { code:"TY2408", expiryDisplay:"31/07/2026", expiryPrecision:"DAY", physical:11, eligible:0, stockState:"EXPIRED", expiryIndicator:"EXPIRED", nearExpiryAction:null },
    { code:"TY2511", expiryDisplay:"11/2027", expiryPrecision:"MONTH", physical:7, eligible:7, stockState:"SELLABLE", expiryIndicator:"NONE", nearExpiryAction:null },
  ]},
  { id:"INV-OXY", name:"Oxytetracycline LA", code:"SP-000147", barcode:"8938500007144", stockUom:"chai", tracking:"NONE", physical:31, eligible:30, reserved:4, available:26, threshold:null, target:null, monitoringConfigStatus:"NOT_CONFIGURED", eligibilityBreakdown:[{reason:"Cách ly",quantity:1}], latestPhysicalMovement:{label:"Nhận hàng",source:"PN-260824-05",delta:31}, reservationSummary:{quantity:4,source:"SO-260827-03"}, lots:[] },
];
let bj01Filter = "ALL";
let bj01Query = "";
let bj01SelectedProductId = "INV-NOB";
let bj01SelectedLotCode = "DH2507";
let bj01LotOpen = false;
let bj01ProvenanceOpen = false;
let bj01QueryAsOf = "09:42 · 27/08/2026";
let bj01RefreshSequence = ["09:47 · 27/08/2026", "09:51 · 27/08/2026"];
let bj01RefreshIndex = 0;

// ---- Chỉ báo
function bj01ProductById(id) { return bj01Products.find((p)=>p.id===id) || bj01Products[0]; }
function bj01Indicators(p) {
  const out=[];
  const configured=p.monitoringConfigStatus!=="NOT_CONFIGURED";
  if(p.available===0) out.push({key:"OUT",label:"Hết hàng",scope:"PRODUCT"});
  if((p.lots||[]).some((l)=>l.expiryIndicator==="EXPIRED")) out.push({key:"EXPIRED",label:"Có lô hết hạn",scope:"LOT"});
  if(configured && p.available>0 && p.threshold!=null && p.available<=p.threshold) out.push({key:"LOW",label:"Tồn thấp",scope:"PRODUCT"});
  if((p.lots||[]).some((l)=>l.expiryIndicator==="NEAR_EXPIRY")) out.push({key:"NEAR",label:"Có lô cận hạn",scope:"LOT"});
  if(!configured) out.push({key:"NOT_CONFIGURED",label:"Chưa có ngưỡng tồn",scope:"MONITORING"});
  return out;
}
function bj01MatchesFilter(p) { return bj01Filter==="ALL" || bj01Indicators(p).some((x)=>x.key===bj01Filter); }
function bj01SearchText(p) { return `${p.name} ${p.code} ${p.barcode || ""}`.toLocaleLowerCase("vi"); }
function bj01MatchesSearch(p) { const q=bj01Query.trim().toLocaleLowerCase("vi"); return !q || bj01SearchText(p).includes(q); }
function bj01AsOf() { return bj01QueryAsOf; }
function bj01PrimaryAttention(p) {
  const all=bj01Indicators(p);
  if(bj01Filter!=="ALL") return all.find((x)=>x.key===bj01Filter) || all.find((x)=>x.key==="NOT_CONFIGURED") || null;
  const priority=["OUT","EXPIRED","LOW","NEAR","NOT_CONFIGURED"];
  return priority.map((k)=>all.find((x)=>x.key===k)).find(Boolean)||null;
}
// Chỉ báo tồn là badge ở cuối dòng; "Chưa có ngưỡng tồn" không phải trạng thái hàng nên ở lại dòng phụ.
const BJ01_STOCK_TONE = {OUT:"Danger",EXPIRED:"Danger",LOW:"Warning",NEAR:"Warning"};
function bj01RowSubtitle(p) {
  const issue=bj01PrimaryAttention(p);
  const inCaption=issue && !BJ01_STOCK_TONE[issue.key];
  return `${p.available} ${p.stockUom} khả dụng${inCaption ? ` · ${issue.label}` : ""}`;
}
function bj01RowBadge(p) {
  const issue=bj01PrimaryAttention(p);
  return issue && BJ01_STOCK_TONE[issue.key] ? ds24DotBadge(issue.label,BJ01_STOCK_TONE[issue.key]) : "";
}


// ---- Thành phần màn
function bj01Context() { return `<p class="ds24-context vet45-text-style-7" data-ds-component="VText" data-ds-prop-style="Body/Small">Kho trung tâm · Dữ liệu đến ${esc(bj01AsOf()).replace(" · ", ", ")}</p>`; }
function bj01SearchAndFilters() {
  const filters=[['ALL','Tất cả'],['OUT','Hết hàng'],['LOW','Tồn thấp'],['NEAR','Cận hạn'],['EXPIRED','Hết hạn']];
  return `${ds24Search(bj01Query,'data-bj01-search','Tên, mã sản phẩm hoặc mã vạch')}<div class="ds24-chip-scroll" aria-label="Lọc tồn kho" data-composed-from="VChip">${filters.map(([k,l])=>ds24Chip(k,l,bj01Filter===k,'data-bj01-filter')).join('')}</div>`;
}
function bj01Empty(filtered=true) {
  return `<div class="ds24-empty" data-ds-component="VEmptyState"><div class="ds24-empty__media" data-ds-component="VEmptyMedia">${icon(filtered?'search':'inbox')}</div><h3 class="vet45-text-style-5" data-ds-component="VEmptyTitle">${filtered?'Không có kết quả phù hợp':'Chưa có dữ liệu tồn kho'}</h3><p class="vet45-text-style-6" data-ds-component="VEmptyDescription">${filtered?'Thử tên, mã sản phẩm hoặc chọn bộ lọc khác.':'Không có dữ liệu trong kho hiện tại.'}</p>${filtered?`<button class="ds24-button ds24-button--secondary" data-bj01-clear type="button" data-ds-component="VButton" data-figma-node="521:529">Xóa tìm kiếm và bộ lọc</button>`:''}</div>`;
}
function bj01AvailabilityRows(p,{showAvailable=true}={}) {
  const unit=esc(p.stockUom);
  const reasons=(p.eligibilityBreakdown||[]).filter((x)=>Number(x.quantity)>0);
  const reasonRows=reasons.length?`<div class="bj01-eligibility-reasons" data-composed-from="DS v2 / Key-value Row">${reasons.map((x)=>ds24KeyValueRow(x.reason,`${x.quantity} ${unit}`)).join('')}</div>`:"";
  return `<section class="ds24-availability${showAvailable?'':' ds24-availability--supporting'}" data-composed-from="DS v2 / Key-value Row">${showAvailable?ds24KeyValueRow('Khả dụng',`${p.available} ${unit}`,true):''}<div class="ds24-key-value-stack">${ds24KeyValueRow('Tồn vật lý',`${p.physical} ${unit}`)}${ds24KeyValueRow('Đủ điều kiện bán',`${p.eligible} ${unit}`)}${ds24KeyValueRow('Đã giữ',`${p.reserved} ${unit}`)}</div>${reasons.length?`${ds24SectionTitle('Không đủ điều kiện bán')}${reasonRows}`:''}</section>`;
}
function bj01LotQuantityRows(lot,p) {
  const unit=esc(p.stockUom);
  return `<section class="ds24-availability ds24-availability--supporting" data-composed-from="DS v2 / Key-value Row"><div class="ds24-key-value-stack">${ds24KeyValueRow('Tồn vật lý',`${lot.physical} ${unit}`)}${ds24KeyValueRow('Đủ điều kiện bán',`${lot.eligible} ${unit}`)}</div></section>`;
}
function bj01AttentionBanner(p) {
  const item=bj01Indicators(p).find((x)=>x.key==="OUT") || bj01Indicators(p).find((x)=>x.key==="LOW");
  if(!item) return "";
  if(item.key==="OUT") {
    const desc=p.target!=null?`Khả dụng 0 ${esc(p.stockUom)}. Gợi ý bổ sung: ${Math.max(0,p.target-p.available)} ${esc(p.stockUom)} để đạt mức mục tiêu ${p.target} ${esc(p.stockUom)}.`:`Khả dụng 0 ${esc(p.stockUom)}${p.threshold!=null?` · Ngưỡng ${p.threshold} ${esc(p.stockUom)}.`:''}`;
    return vBanner("error","Hết hàng",desc);
  }
  const parts=[`Khả dụng ${p.available} ${esc(p.stockUom)}${p.threshold!=null?` · Ngưỡng ${p.threshold} ${esc(p.stockUom)}.`:''}`];
  if(p.target!=null&&p.target>p.available) parts.push(`Gợi ý bổ sung: ${p.target-p.available} ${esc(p.stockUom)} để đạt mức mục tiêu ${p.target} ${esc(p.stockUom)}.`);
  return vBanner("warning","Tồn thấp",parts.join(' '));
}
function bj01LotSheet(p) {
  if(!bj01LotOpen) return ""; const lot=(p.lots||[]).find((x)=>x.code===bj01SelectedLotCode)||p.lots?.[0]; if(!lot)return "";
  let status="";
  if(lot.expiryIndicator==='EXPIRED') status=vBanner('error','Hết hạn','Lượng của lô này không đủ điều kiện bán.');
  else if(lot.expiryIndicator==='NEAR_EXPIRY'&&lot.nearExpiryAction==='BLOCK_SALE') status=vBanner('warning','Cận hạn · Đã chặn bán','Lượng của lô này không tính vào khả dụng theo chính sách hiện tại.');
  else if(lot.expiryIndicator==='NEAR_EXPIRY') status=vBanner('warning','Cận hạn',`${lot.daysToExpiry!=null?`Còn ${lot.daysToExpiry} ngày · `:''}vẫn đủ điều kiện bán theo chính sách hiện tại.`);
  return ds24Sheet({title:`Lô ${lot.code}`,attrs:'data-bj01-close-lot',body:`<p class="ds24-context vet45-text-style-7">${esc(p.name)} · HSD ${esc(lot.expiryDisplay)}</p>${bj01LotQuantityRows(lot,p)}${status}`});
}
function bj01ProvenanceSheet(p) {
  if(!bj01ProvenanceOpen)return "";
  const mv=p.latestPhysicalMovement||{}; const rs=p.reservationSummary||{};
  const movementValue=mv.source?`${mv.source} · ${Number(mv.delta)>0?'+':''}${mv.delta} ${p.stockUom}`:'Chưa có biến động';
  const reservationValue=Number(rs.quantity)>0?`${rs.quantity} ${p.stockUom}${rs.source?` · ${rs.source}`:''}`:`0 ${p.stockUom}`;
  return ds24Sheet({title:'Nguồn và thời điểm cập nhật',attrs:'data-bj01-close-provenance',body:`<p class="ds24-context vet45-text-style-7">${esc(p.name)} · Kho trung tâm</p><div class="ds24-info-stack">${ds24InfoRow('Dữ liệu đến',bj01AsOf())}${ds24InfoRow(mv.label?`${mv.label} gần nhất`:'Biến động gần nhất',movementValue)}${ds24InfoRow('Đang giữ',reservationValue)}</div><button class="ds24-button ds24-button--secondary" data-bj01-handoff type="button" data-ds-component="VButton" data-figma-node="521:529">${icon('history','icon--sm')}Xem thẻ kho và lịch sử</button>`});
}

// ---- Màn
function render001BJ01(state) {
  if(state==="PERMISSION_DENIED") return appShell({title:"Tồn kho",body:deniedBody(),centered:true,back:false});
  if(state==="LOADING") return appShell({title:"Tồn kho",body:bj01Context()+loadingBody(),back:false});
  const stale=state==="STALE"?`${vBanner("warning","Dữ liệu có thể đã cũ","Hãy làm mới trước khi sử dụng.")}<button class="ds24-button ds24-button--secondary ds24-inline-action" data-bj01-refresh type="button" data-ds-component="VButton" data-figma-node="521:529">${icon('rotate','icon--sm')}Làm mới</button>`:"";
  const visible=state==="EMPTY"||state==="FILTER_EMPTY"?[]:bj01Products.filter((p)=>bj01MatchesFilter(p)&&bj01MatchesSearch(p));
  const empty=state==="EMPTY"?bj01Empty(false):(!visible.length?bj01Empty(true):"");
  const rows=visible.map((p)=>ds24ListRow({title:`${p.name} · ${p.code}`,subtitle:bj01RowSubtitle(p),trailing:bj01RowBadge(p),attrs:`data-bj01-product="${p.id}" data-bj01-search-text="${escapeAttribute(bj01SearchText(p))}"`,})).join('');
  const body=`${bj01Context()}${stale}${bj01SearchAndFilters()}${rows?`<section class="ds24-list-stack" data-composed-from="DS v2 / List Row">${rows}</section>`:''}${empty}`;
  return appShell({title:"Tồn kho",body,back:false});
}
function render003BJ01(state) {
  const entrySubtitle=entryMode==="product-context"?"Từ ngữ cảnh sản phẩm · Kho trung tâm":null;
  const entryBack=entryMode==="product-context"?"exit-inventory-product-context":"";
  if(state==="PERMISSION_DENIED") return appShell({title:"Chi tiết tồn kho",subtitle:entrySubtitle,body:deniedBody(),centered:true,back:true,backAction:entryBack});
  if(state==="LOADING") return appShell({title:"Chi tiết tồn kho",subtitle:entrySubtitle,body:loadingBody(),back:true,backAction:entryBack});
  const p=bj01ProductById(bj01SelectedProductId);
  const stale=state==="STALE"?`${vBanner("warning","Dữ liệu có thể đã cũ",`Dữ liệu đến ${esc(bj01AsOf())}. Hãy làm mới trước khi sử dụng.`)}<button class="ds24-button ds24-button--secondary ds24-inline-action" data-bj01-refresh type="button" data-ds-component="VButton" data-figma-node="521:529">${icon('rotate','icon--sm')}Làm mới</button>`:"";
  const productContext=ds24ListRow({title:p.name,subtitle:`${p.code} · ${p.stockUom}`,leading:'package',type:'Status',interactive:false,density:'Compact',attrs:'data-ds-role="inventory-product-summary"'});
  const configNote=p.monitoringConfigStatus==='NOT_CONFIGURED'?`<p class="ds24-context bj01-config-note" data-ds-component="VText">Chưa cấu hình ngưỡng tồn; chưa thể xác định trạng thái tồn thấp/bình thường.</p>`:"";
  let body=`${bj01Context()}${stale}${productContext}${bj01AvailabilityRows(p)}${configNote}${bj01AttentionBanner(p)}`;
  if(p.tracking==='LOT') {
    const lots=p.lots.map((lot)=>{const badge=lot.expiryIndicator==='NEAR_EXPIRY'?ds24DotBadge('Cận hạn','Warning'):lot.expiryIndicator==='EXPIRED'?ds24DotBadge('Hết hạn','Danger'):'';return ds24ListRow({title:`Lô ${lot.code}`,subtitle:`HSD ${lot.expiryDisplay} · Tồn ${lot.physical} ${p.stockUom}`,trailing:badge,leading:null,attrs:`data-bj01-lot="${escapeAttribute(lot.code)}"`,});}).join('');
    body+=`<section class="ds24-section">${ds24SectionTitle('Lô và hạn dùng',`${p.lots.length} lô`)}<div class="ds24-list-stack">${lots}</div></section>`;
  }
  body+=`<section class="ds24-section">${ds24ListRow({title:'Nguồn và thời điểm cập nhật',subtitle:'Xem nguồn số liệu và lịch sử',leading:'history',attrs:'data-bj01-provenance',})}</section>${bj01LotSheet(p)}${bj01ProvenanceSheet(p)}`;
  return appShell({title:"Chi tiết tồn kho",subtitle:entrySubtitle,body,back:true,backAction:entryBack});
}
function render004BJ01(state) { bj01LotOpen=true; return render003BJ01(state==="PERMISSION_DENIED"?state:state==="LOADING"?state:"READY"); }

Object.assign(renderers, { "SCR-001": render001BJ01, "SCR-003": render003BJ01, "SCR-004": render004BJ01 });
ownedFlows.add("UIF-01");

// ---- Sự kiện
document.addEventListener("click", (event) => {
  if (activeFlowId === "UIF-01") {
    const product = event.target.closest("[data-bj01-product]");
    if (product) { bj01SelectedProductId=product.dataset.bj01Product; bj01LotOpen=false; bj01ProvenanceOpen=false; return navigate("SCR-003"); }
    const lot = event.target.closest("[data-bj01-lot]");
    if (lot) { bj01SelectedLotCode=lot.dataset.bj01Lot; bj01LotOpen=true; bj01ProvenanceOpen=false; return renderAppScreen(); }
    const filter = event.target.closest("[data-bj01-filter]");
    if (filter) { bj01Filter=filter.dataset.bj01Filter; stateByScreen["SCR-001"]="READY"; return render(); }
    if (event.target.closest("[data-bj01-clear]")) { bj01Query=""; bj01Filter="ALL"; stateByScreen["SCR-001"]="READY"; return render(); }
    if (event.target.closest("[data-bj01-provenance]")) { bj01ProvenanceOpen=true; bj01LotOpen=false; return renderAppScreen(); }
    if (event.target.matches("[data-bj01-close-provenance]") || event.target.closest("button[data-bj01-close-provenance]")) { bj01ProvenanceOpen=false; return renderAppScreen(); }
    if (event.target.matches("[data-bj01-close-lot]") || event.target.closest("button[data-bj01-close-lot]")) { bj01LotOpen=false; return renderAppScreen(); }
    if (event.target.closest("[data-bj01-refresh]")) { bj01QueryAsOf=bj01RefreshSequence[Math.min(bj01RefreshIndex,bj01RefreshSequence.length-1)]; bj01RefreshIndex=Math.min(bj01RefreshIndex+1,bj01RefreshSequence.length-1); stateByScreen[activeScreenId]="READY"; render(); return showToast("Đã cập nhật tồn kho","success"); }
    if (event.target.closest("[data-bj01-handoff]")) {
      bj01ProvenanceOpen=false; bj01LotOpen=false; activeFlowId="UIF-15"; activeScreenId="SCR-054"; syncReviewUrl(); return render();
    }
  }
  const exit = event.target.closest('[data-action="exit-inventory-product-context"]');
  if (exit && activeFlowId === "UIF-01") { const p=bj01ProductById(bj01SelectedProductId); return showToast(`Quay về sản phẩm ${p?.name || "đang xem"}`, "info"); }
});

document.addEventListener("input", (event) => {
  if (activeFlowId === "UIF-01" && event.target.matches("[data-bj01-search]")) {
    bj01Query=event.target.value;
    const q=bj01Query.trim().toLocaleLowerCase("vi");
    let visible=0;
    document.querySelectorAll("[data-bj01-search-text]").forEach((row)=>{ const show=!q || row.dataset.bj01SearchText.includes(q); row.hidden=!show; if(show) visible+=1; });
    const empty=document.querySelector("[data-bj01-empty]"); if(empty) empty.hidden=visible!==0;
    return;
  }
});
