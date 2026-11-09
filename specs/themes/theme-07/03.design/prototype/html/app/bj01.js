/* BJ-01 — Theo dõi tồn, khả dụng và chỉ báo vận hành (UIF-01). Màn: SCR-001 Tồn kho, SCR-003 Chi tiết tồn kho
 * (SCR-004 = SCR-003 với sheet lô đang mở).
 *
 * Đã viết lại sạch (T7-P bước A, 2026-10-16): mọi hàm dựng, fixture và xử lý sự kiện của BJ-01 nằm ở đây.
 * Sửa BJ-01: sửa thẳng file này.
 * Dùng chung từ app/core.js: appShell, ds24* (ListRow, Badge, DotBadge, Chip, Search, KeyValueRow, InfoRow, Sheet,
 * SectionTitle), vBanner, deniedBody, loadingBody, icon, esc, escapeAttribute, navigate, render, renderAppScreen.
 * Empty state: ds24EmptyState ở core.js (bj01Empty giữ bí danh; BJ-08 cũng gọi).
 */

// ---- Fixture và trạng thái màn
const bj01Products = [
  { id:"INV-NOB", name:"Nobivac DHPPi", code:"SP-000184", barcode:"8938500001012", stockUom:"hộp", tracking:"LOT", physical:120, eligible:118, reserved:12, available:106, threshold:30, target:80, monitoringConfigStatus:"CONFIGURED", eligibilityBreakdown:[{reason:"Cách ly",quantity:2}], latestPhysicalMovement:{label:"Nhận hàng",source:"PN-260816-04",delta:118}, reservationSummary:{quantity:12,source:"SO-260827-21"}, lots:[
    { code:"DH2507", expiryDisplay:"30/11/2026", expiryPrecision:"DAY", physical:70, eligible:70, stockState:"SELLABLE", expiryIndicator:"NONE", nearExpiryAction:null },
    { code:"DH2509", expiryDisplay:"30/09/2026", expiryPrecision:"DAY", physical:50, eligible:48, stockState:"SELLABLE", expiryIndicator:"NEAR_EXPIRY", nearExpiryAction:"WARN", daysToExpiry:13 },
  ]},
  { id:"INV-AMX", name:"Amox 500", code:"SP-000066", barcode:"8938500004068", stockUom:"hộp", tracking:"NONE", physical:48, eligible:46, reserved:5, available:41, threshold:50, target:80, monitoringConfigStatus:"CONFIGURED", eligibilityBreakdown:[{reason:"Cách ly",quantity:2}], latestPhysicalMovement:{label:"Nhận hàng",source:"PN-260825-02",delta:48}, reservationSummary:{quantity:5,source:"SO-260827-18"}, lots:[] },
  { id:"INV-ENRO", name:"Enrofloxacin 10%", code:"SP-000091", barcode:"8938500005096", stockUom:"chai", tracking:"NONE", physical:0, eligible:0, reserved:0, available:0, threshold:10, target:30, monitoringConfigStatus:"CONFIGURED", eligibilityBreakdown:[], latestPhysicalMovement:{label:"Xuất bán",source:"SO-260826-11",delta:-6}, reservationSummary:{quantity:0,source:null}, lots:[] },
  { id:"INV-TYLO", name:"Tylosin 20%", code:"SP-000122", barcode:"8938500006123", stockUom:"lọ", tracking:"LOT", physical:14, eligible:3, reserved:1, available:2, threshold:8, target:24, monitoringConfigStatus:"CONFIGURED", eligibilityBreakdown:[{reason:"Hết hạn",quantity:11}], latestPhysicalMovement:{label:"Nhận hàng",source:"PN-260701-07",delta:18}, reservationSummary:{quantity:1,source:"SO-260826-09"}, lots:[
    { code:"TY2408", expiryDisplay:"31/07/2026", expiryPrecision:"DAY", physical:11, eligible:0, stockState:"EXPIRED", expiryIndicator:"EXPIRED", nearExpiryAction:null },
    { code:"TY2511", expiryDisplay:"11/2027", expiryPrecision:"MONTH", physical:3, eligible:3, stockState:"SELLABLE", expiryIndicator:"NONE", nearExpiryAction:null },
  ]},
  { id:"INV-OXY", name:"Oxytetracycline LA", code:"SP-000147", barcode:"8938500007144", stockUom:"chai", tracking:"NONE", physical:12, eligible:11, reserved:4, available:7, threshold:null, target:null, monitoringConfigStatus:"NOT_CONFIGURED", eligibilityBreakdown:[{reason:"Cách ly",quantity:1}], latestPhysicalMovement:{label:"Nhận hàng",source:"PN-260824-05",delta:31}, reservationSummary:{quantity:4,source:"SO-260827-03"}, lots:[] },
];
// v5.28.0 rút gọn: không còn giữ hàng (BJ-04), tình trạng cách ly / hỏng (BJ-09), mức tồn mục tiêu (CAP-01).
// Khả dụng = tồn của các lô còn hạn; lô hết hạn chờ điều chỉnh giảm qua Kiểm kê.
bj01Products.forEach((p) => {
  (p.lots || []).forEach((l) => { if (l.stockState !== "EXPIRED") { l.eligible = l.physical; l.stockState = "SELLABLE"; } });
  const expired = (p.lots || []).filter((l) => l.stockState === "EXPIRED").reduce((n, l) => n + l.physical, 0);
  p.eligible = p.physical - expired; p.reserved = 0; p.available = p.eligible; p.target = null;
  p.eligibilityBreakdown = expired ? [{ reason: "Hết hạn", quantity: expired }] : [];
});
let bj01Filter = "ALL";
let bj01Query = "";
let bj01SelectedProductId = "INV-NOB";
let bj01WebSelectedId = null; // dòng đang chọn ở SCR-001 khung web (null = dòng đầu của danh sách đang hiện); iPhone bỏ qua
let bj01SelectedLotCode = "DH2507";
let bj01LotOpen = false;
let bj01ProvenanceOpen = false;
let bj01ScanOpen = false;
// Mốc dữ liệu = mốc của sổ kho BJ-15 (BJ15_AS_OF); "Làm mới" nhích thêm vài phút.
let bj01QueryAsOf = "21:30 · 17/09/2026";
let bj01RefreshSequence = ["21:34 · 17/09/2026", "21:38 · 17/09/2026"];
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
  if(!configured) out.push({key:"NOT_CONFIGURED",label:"Chưa đặt tồn tối thiểu",scope:"MONITORING"});
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
  return inCaption ? `${p.code} · ${issue.label}` : p.code;
}
function bj01RowBadge(p) {
  const issue=bj01PrimaryAttention(p);
  return issue && BJ01_STOCK_TONE[issue.key] ? ds24DotBadge(issue.label,BJ01_STOCK_TONE[issue.key]) : "";
}

// Khung web: bảng danh sách – chi tiết (T7-HF1). Cột Chỉ báo dùng badge như dòng iPhone; "Chưa có ngưỡng tồn" là badge trung tính.
function bj01TableRow(p) {
  const issue=bj01PrimaryAttention(p);
  const unit=p.stockUom;
  return { id:p.id, name:p.name, code:p.code, product:`<strong>${esc(p.name)}</strong><small>${esc(p.code)}</small>`, available:`${p.available} ${unit}`, physical:`${p.physical} ${unit}`, reserved:`${p.reserved} ${unit}`, badge:bj01RowBadge(p)||(issue?ds24Badge(issue.label,"Neutral"):"") };
}
const BJ01_COLUMNS = [
  { key:"product", label:"Sản phẩm", html:true },
  { key:"available", label:"Khả dụng", align:"end", mono:true },
  { key:"physical", label:"Tồn vật lý", align:"end", mono:true },
  { key:"reserved", label:"Đã giữ", align:"end", mono:true },
  { key:"badge", label:"Chỉ báo", html:true },
];

// Thứ tự mức gấp ở "Tất cả": Hết hàng → có lô hết hạn → Tồn thấp → có lô cận hạn → bình thường → chưa có ngưỡng.
const BJ01_URGENCY = ["OUT","EXPIRED","LOW","NEAR"];
function bj01UrgencyRank(p) {
  const keys=bj01Indicators(p).map((x)=>x.key);
  const i=BJ01_URGENCY.findIndex((k)=>keys.includes(k));
  if(i>=0) return i;
  return keys.includes("NOT_CONFIGURED") ? BJ01_URGENCY.length+1 : BJ01_URGENCY.length;
}
function bj01FilterCount(key) { return key==="ALL" ? bj01Products.length : bj01Products.filter((p)=>bj01Indicators(p).some((x)=>x.key===key)).length; }
// HSD gần nhất trước: DAY dd/mm/yyyy, MONTH mm/yyyy (cuối tháng), YEAR yyyy (31/12); không có → cuối danh sách.
function bj01ExpirySortKey(lot) {
  const parts=String(lot.expiryDisplay||"").split("/").map(Number);
  if(lot.expiryPrecision==="DAY" && parts.length===3) return new Date(parts[2],parts[1]-1,parts[0]).getTime();
  if(lot.expiryPrecision==="MONTH" && parts.length===2) return new Date(parts[1],parts[0],0).getTime();
  if(lot.expiryPrecision==="YEAR" && parts.length===1 && parts[0]) return new Date(parts[0],11,31).getTime();
  return Infinity;
}

// ---- Thành phần màn
function bj01Context() { return `<p class="ds24-context vet45-text-style-7" data-ds-component="VText" data-ds-prop-style="Body/Small">Kho trung tâm · Dữ liệu đến ${esc(bj01AsOf()).replace(" · ", ", ")}</p>`; }
function bj01SearchAndFilters() {
  const filters=[['ALL','Tất cả'],['OUT','Hết hàng'],['LOW','Tồn thấp'],['NEAR','Cận hạn'],['EXPIRED','Hết hạn']];
  const scan=`<button type="button" class="ds24-search__action" data-bj01-scan aria-label="Quét mã vạch">${icon("scan","icon--sm")}</button>`;
  return `${ds24Search(bj01Query,'data-bj01-search','Tên, mã sản phẩm hoặc mã vạch',scan)}<div class="ds24-chip-scroll" aria-label="Lọc tồn kho" data-composed-from="VChip">${filters.map(([k,l])=>ds24Chip(k,l,bj01Filter===k,'data-bj01-filter',bj01FilterCount(k))).join('')}</div>`;
}
function bj01Empty(filtered=true){ return ds24EmptyState(filtered); }
// Đặt / sửa ngưỡng tồn: chủ cửa hàng (CAP-01 chỉ cho nhân viên xem).
const bj01CanSetThreshold=()=>currentActor()!=="staff";
function bj01StockHero(p) {
  const unit=esc(p.stockUom);
  const issue=bj01Indicators(p).find((x)=>x.key==="OUT")||bj01Indicators(p).find((x)=>x.key==="LOW");
  const badge=issue?ds24DotBadge(issue.label,BJ01_STOCK_TONE[issue.key]):"";
  const reasons=(p.eligibilityBreakdown||[]).filter((x)=>Number(x.quantity)>0).map((x)=>`${x.reason} ${x.quantity} ${p.stockUom}`);
  const stat=(label,value)=>`<div><dt>${esc(label)}</dt><dd>${esc(value)} ${unit}</dd></div>`;
  // Ngưỡng của sản phẩm đã cấu hình: một dòng cuối thẻ + "Sửa ngưỡng" (CAP-01); nhân viên chỉ thấy số.
  // v5.28.0: chỉ còn "Tồn tối thiểu" của sản phẩm (sửa ở hồ sơ sản phẩm Theme 2; CAP-01 đã bỏ).
  const policy=p.monitoringConfigStatus!=="NOT_CONFIGURED"&&p.threshold!=null?`<div class="bj01-stock-hero__policy"><span>Tồn tối thiểu ${esc(p.threshold)} ${unit}</span></div>`:"";
  return `<section class="bj01-stock-hero" data-composed-from="VCard,DS v2 / Key-value Row"><div class="bj01-stock-hero__main"><span>Khả dụng</span><strong>${esc(p.available)} ${unit}</strong>${badge}</div><dl class="bj01-stock-hero__stats">${stat("Tồn vật lý",p.physical)}</dl>${reasons.length?`<p class="bj01-stock-hero__note">Không đủ điều kiện bán: ${esc(reasons.join(" · "))}</p>`:""}${policy}</section>`;
}
function bj01LotQuantityRows(lot,p) {
  const unit=esc(p.stockUom);
  return `<section class="ds24-availability ds24-availability--supporting" data-composed-from="DS v2 / Key-value Row"><div class="ds24-key-value-stack">${ds24KeyValueRow('Tồn vật lý',`${lot.physical} ${unit}`)}${ds24KeyValueRow('Đủ điều kiện bán',`${lot.eligible} ${unit}`)}</div></section>`;
}
function bj01Attention(p) {
  const unit=esc(p.stockUom);
  const inds=bj01Indicators(p);
  const item=inds.find((x)=>x.key==="OUT")||inds.find((x)=>x.key==="LOW");
  let html="";
  if(item) {
    const desc=item.key==="OUT"
      ? `Khả dụng 0 ${unit}${p.threshold!=null?` · Tồn tối thiểu ${p.threshold} ${unit}.`:'.'}`
      : `Khả dụng ${p.available} ${unit}${p.threshold!=null?` · Tồn tối thiểu ${p.threshold} ${unit}.`:'.'}`;
    const hint=p.target!=null&&p.target>p.available?`<p class="bj01-attention__hint">Gợi ý nhập thêm ${p.target-p.available} ${unit} (mục tiêu ${p.target} ${unit})</p>`:"";
    html+=`<div class="bj01-attention">${vBanner(item.key==="OUT"?"error":"warning",item.label,desc)}${hint}<button class="ds24-button ds24-button--secondary" data-bj01-receive type="button" data-ds-component="VButton" data-figma-node="521:529">Nhận hàng</button></div>`;
  }
  const expired=(p.lots||[]).filter((l)=>l.expiryIndicator==="EXPIRED");
  if(expired.length) {
    const qty=expired.reduce((sum,l)=>sum+Number(l.physical||0),0);
    html+=`<div class="bj01-attention">${vBanner("error","Có lô hết hạn",`Lô ${esc(expired.map((l)=>l.code).join(" · "))} · ${qty} ${unit} không đủ điều kiện bán.`)}<button class="ds24-button ds24-button--secondary" data-bj01-dispose-lot="${escapeAttribute(expired[0].code)}" type="button" data-ds-component="VButton" data-figma-node="521:529">Điều chỉnh lô hết hạn</button></div>`;
  }
  return html;
}
function bj01ScanSheet() {
  if(!bj01ScanOpen) return "";
  return ds24Sheet({title:"Quét mã vạch",attrs:"data-bj01-scan-close",body:`<div class="bj01-scan-frame" aria-hidden="true">${icon("scan")}</div><p class="ds24-context vet45-text-style-7">Đưa mã vạch vào khung</p><button class="ds24-button ds24-button--secondary" data-bj01-scan-sample="INV-AMX" type="button" data-ds-component="VButton" data-figma-node="521:529">Quét thử: Amox 500</button>`});
}
// Lô của BJ-01 có trong fixture "Hàng có vấn đề" (t7Lots) thì đổi tình trạng / xử lý hết hạn được ở BJ-09.
function bj01T7Lot(p, lotCode) { return typeof t7Lots !== "undefined" ? t7Lots.find((l) => l.code === p.code && l.lot === lotCode) : null; }
function bj01LotSheet(p) {
  if(!bj01LotOpen) return ""; const lot=(p.lots||[]).find((x)=>x.code===bj01SelectedLotCode)||p.lots?.[0]; if(!lot)return "";
  let status="";
  if(lot.expiryIndicator==='EXPIRED') status=vBanner('error','Hết hạn','Lượng của lô này không đủ điều kiện bán.');
  else if(lot.expiryIndicator==='NEAR_EXPIRY'&&lot.nearExpiryAction==='BLOCK_SALE') status=vBanner('warning','Cận hạn · Đã chặn bán','Lượng của lô này không tính vào khả dụng theo chính sách hiện tại.');
  else if(lot.expiryIndicator==='NEAR_EXPIRY') status=vBanner('warning','Cận hạn',`${lot.daysToExpiry!=null?`Còn ${lot.daysToExpiry} ngày · `:''}vẫn đủ điều kiện bán theo chính sách hiện tại.`);
  const t7 = bj01T7Lot(p, lot.code);
  const dispose=lot.expiryIndicator==='EXPIRED'?`<button class="ds24-button ds24-button--secondary" data-bj01-dispose-lot="${escapeAttribute(lot.code)}" type="button" data-ds-component="VButton" data-figma-node="521:529">Điều chỉnh lô hết hạn</button>`
    :''; // v5.28.0: bỏ "Đổi tình trạng" (BJ-09)
  return ds24Sheet({title:`Lô ${lot.code}`,attrs:'data-bj01-close-lot',body:`<p class="ds24-context vet45-text-style-7">${esc(p.name)} · HSD ${esc(lot.expiryDisplay)}</p>${bj01LotQuantityRows(lot,p)}${status}${dispose}`});
}
// Biến động vật lý gần nhất đọc từ sổ kho (BJ-15); chưa nạp sổ thì dùng số liệu mẫu của sản phẩm.
function bj01LatestMovement(p) {
  if (typeof BJ15_MOVES === "undefined") return p.latestPhysicalMovement||{};
  const last = BJ15_MOVES.filter((m) => m.productId === p.id && m.delta !== 0).sort((a, b) => (a.rKey < b.rKey ? -1 : a.rKey > b.rKey ? 1 : a.seq - b.seq)).pop();
  return last ? { label: last.kind, source: last.doc, delta: last.delta, receipt: last.sourceFlow === "UIF-02" && last.kind === "Nhận hàng" } : (p.latestPhysicalMovement||{});
}
function bj01ProvenanceSheet(p) {
  if(!bj01ProvenanceOpen)return "";
  const mv=bj01LatestMovement(p); const rs=p.reservationSummary||{};
  const movementValue=mv.source?`${mv.source} · ${Number(mv.delta)>0?'+':''}${mv.delta} ${p.stockUom}`:'Chưa có biến động';
  const reservationValue=Number(rs.quantity)>0?`${rs.quantity} ${p.stockUom}${rs.source?` · ${rs.source}`:''}`:`0 ${p.stockUom}`;
  return ds24Sheet({title:'Nguồn và thời điểm cập nhật',attrs:'data-bj01-close-provenance',body:`<p class="ds24-context vet45-text-style-7">${esc(p.name)} · Kho trung tâm</p><div class="ds24-info-stack">${ds24InfoRow('Dữ liệu đến',bj01AsOf())}${ds24InfoRow(mv.label?`${mv.label} gần nhất`:'Biến động gần nhất',movementValue)}${mv.receipt?`<button class="k7-row-link" type="button" data-bj01-open-receipt="${escapeAttribute(mv.source)}">Mở phiếu nhận ${esc(mv.source)}</button>`:''}${ds24InfoRow('Đang giữ',reservationValue)}</div><button class="ds24-button ds24-button--secondary" data-bj01-handoff type="button" data-ds-component="VButton" data-figma-node="521:529">${icon('history','icon--sm')}Xem thẻ kho và lịch sử</button>`});
}

// ---- Màn
function bj01Stale(withDate) {
  return k1Stale({title:"Dữ liệu có thể đã cũ",description:withDate?`Dữ liệu đến ${bj01AsOf()}. Hãy làm mới trước khi sử dụng.`:"Hãy làm mới trước khi sử dụng.",actionLabel:"Làm mới",actionAttr:"data-bj01-refresh"});
}
// Chi tiết một sản phẩm (cột phải của SCR-001 trên web, thân của SCR-003): trái thẻ số + ngưỡng, phải lô + nguồn.
// iPhone: các lớp bọc là display:contents nên thứ tự và khoảng cách như cũ.
function bj01DetailBody(p) {
  const configNote=p.monitoringConfigStatus==='NOT_CONFIGURED'?`<p class="ds24-context bj01-config-note" data-ds-component="VText">Chưa đặt tồn tối thiểu (ở hồ sơ sản phẩm); chưa xác định được tồn thấp.</p>`:'';
  let more="";
  if(p.tracking==='LOT') {
    const sorted=[...p.lots].sort((x,y)=>bj01ExpirySortKey(x)-bj01ExpirySortKey(y));
    const lotBadge=(lot)=>lot.expiryIndicator==='NEAR_EXPIRY'?ds24DotBadge('Cận hạn','Warning'):lot.expiryIndicator==='EXPIRED'?ds24DotBadge('Hết hạn','Danger'):'';
    // Web: bảng lô (Lô · HSD · Tồn · Tình trạng), bấm / Enter mở sheet lô; iPhone: danh sách thẻ như cũ.
    const lots=viewport==="web"
      ? k7Table({columns:[{key:"code",label:"Lô",html:true},{key:"expiry",label:"HSD",mono:true},{key:"physical",label:"Tồn",align:"end",mono:true},{key:"badge",label:"Tình trạng",html:true}],caption:"Lô và hạn dùng",
          rows:sorted.map((lot)=>({code:`<strong>Lô ${esc(lot.code)}</strong>`,expiry:lot.expiryDisplay,physical:`${lot.physical} ${p.stockUom}`,badge:lotBadge(lot),lot})),
          mobileRow:(r)=>ds24ListRow({title:`Lô ${r.lot.code}`,subtitle:`HSD ${r.lot.expiryDisplay} · Tồn ${r.lot.physical} ${p.stockUom}`,trailing:r.badge,leading:null,attrs:`data-bj01-lot="${escapeAttribute(r.lot.code)}"`}),
          rowAttr:(r)=>`data-bj01-lot="${escapeAttribute(r.lot.code)}"`,rowOpen:true})
      : `<div class="ds24-list-stack">${sorted.map((lot)=>ds24ListRow({title:`Lô ${lot.code}`,subtitle:`HSD ${lot.expiryDisplay} · Tồn ${lot.physical} ${p.stockUom}`,trailing:lotBadge(lot),leading:null,attrs:`data-bj01-lot="${escapeAttribute(lot.code)}"`,})).join('')}</div>`;
    more+=`<section class="ds24-section">${ds24SectionTitle('Lô và hạn dùng',`${p.lots.length} lô`)}${lots}</section>`;
  }
  more+=`<section class="ds24-section">${ds24ListRow({title:'Nguồn và thời điểm cập nhật',subtitle:'Xem nguồn số liệu và lịch sử',leading:'history',attrs:'data-bj01-provenance',})}</section>`;
  return `<div class="bj01-detail"><div class="bj01-detail__summary">${bj01StockHero(p)}${bj01Attention(p)}${configNote}</div><div class="bj01-detail__more">${more}</div></div>`;
}
function render001BJ01(state) {
  const wide="k7-wide"; // chỉ có tác dụng ở khung web: thanh tiêu đề phủ hết khung
  if(state==="PERMISSION_DENIED") return appShell({title:"Tồn kho",body:k1Denied({what:"xem tồn kho",next:"Bạn chưa được cấp quyền xem tồn kho. Liên hệ chủ cửa hàng nếu cần.",exitAttr:k1ExitAttr("SCR-001")}),centered:true,back:false,extraClass:wide});
  if(state==="LOADING") return appShell({title:"Tồn kho",body:bj01Context()+k1Loading({blocks:["search","row","row","row","row"]}),back:false,extraClass:wide});
  const stale=state==="STALE"?bj01Stale(false):"";
  let visible=state==="EMPTY"||state==="FILTER_EMPTY"?[]:bj01Products.filter((p)=>bj01MatchesFilter(p)&&bj01MatchesSearch(p));
  if(bj01Filter==="ALL") visible=visible.map((p,i)=>({p,i,r:bj01UrgencyRank(p)})).sort((x,y)=>x.r-y.r||x.i-y.i).map((x)=>x.p);
  const empty=state==="EMPTY"?bj01Empty(false):(!visible.length?bj01Empty(true):"");
  const web=viewport==="web";
  const rowAttrs=(p)=>`data-bj01-product="${p.id}" data-bj01-search-text="${escapeAttribute(bj01SearchText(p))}"`;
  if(web && visible.length) {
    // Danh sách – chi tiết: bấm dòng đổi chi tiết bên phải, không đổi trang. Dòng chọn mặc định = dòng đầu.
    const selected=visible.find((p)=>p.id===bj01WebSelectedId)||visible[0];
    bj01SelectedProductId=selected.id;
    const table=k7Table({columns:BJ01_COLUMNS,rows:visible.map(bj01TableRow),caption:"Tồn kho",
      mobileRow:(r)=>ds24StockRow({title:r.name,subtitle:r.code,quantity:r.available,badge:r.badge,attrs:rowAttrs(bj01ProductById(r.id))}),
      rowAttr:(r)=>`${rowAttrs(bj01ProductById(r.id))}${r.id===selected.id?' aria-current="true" class="is-selected"':""}`,rowOpen:true});
    const main=`${bj01Context()}${stale}${bj01SearchAndFilters()}${table}${bj01ScanSheet()}${bj01LotSheet(selected)}${bj01ProvenanceSheet(selected)}`;
    return appShell({title:"Tồn kho",body:`<div class="bj01-list-detail">${k7Split({main,aside:bj01DetailBody(selected),asideWebOnly:true})}</div>`,back:false,extraClass:wide});
  }
  const rows=visible.map((p)=>ds24StockRow({title:p.name,subtitle:bj01RowSubtitle(p),quantity:`${p.available} ${p.stockUom}`,badge:bj01RowBadge(p),attrs:rowAttrs(p)})).join('');
  const body=`${bj01Context()}${stale}${bj01SearchAndFilters()}${rows?`<section class="ds24-list-stack" data-composed-from="DS v2 / List Row">${rows}</section>`:''}${empty}${bj01ScanSheet()}`;
  return appShell({title:"Tồn kho",body,back:false,extraClass:wide});
}
function render003BJ01(state) {
  const entryBack=entryMode==="product-context"?"exit-inventory-product-context":"";
  if(state==="PERMISSION_DENIED") return appShell({title:"Chi tiết tồn kho",body:k1Denied({what:"xem tồn kho",next:"Bạn chưa được cấp quyền xem tồn kho. Liên hệ chủ cửa hàng nếu cần.",exitAttr:k1ExitAttr("SCR-001")}),centered:true,back:true,backAction:entryBack,extraClass:"k7-wide"});
  const p=bj01ProductById(bj01SelectedProductId);
  const title=p.name, subtitle=`${p.code} · ${p.stockUom}`;
  if(state==="LOADING") return appShell({title,subtitle,body:bj01Context()+k1Loading({blocks:["card","row","row","row"]}),back:true,backAction:entryBack,extraClass:"k7-wide"});
  const stale=state==="STALE"?bj01Stale(true):"";
  const body=`${bj01Context()}${stale}${bj01DetailBody(p)}${bj01LotSheet(p)}${bj01ProvenanceSheet(p)}`;
  return appShell({title,subtitle,body,back:true,backAction:entryBack,extraClass:"k7-wide"});
}
function render004BJ01(state) { bj01LotOpen=true; return render003BJ01(state==="PERMISSION_DENIED"?state:state==="LOADING"?state:"READY"); }

Object.assign(renderers, { "SCR-001": render001BJ01, "SCR-003": render003BJ01, "SCR-004": render004BJ01 });

// Nhận hàng xong (BJ-02): ghi vào sổ chung (t7Ledger), tồn BJ-01 và thẻ kho BJ-15 cùng đổi. lines: [{ productRef, accepted, quarantine, damaged, lots:[{ code, expiry, expiryPrecision, accepted, quarantine, damaged }] }]
// đã quy về ĐVT tồn của sản phẩm. Đạt vào khả dụng; Đạt + Cách ly + Hỏng vào tồn vật lý.
function bj01ApplyReceipt(lines, ref, note = "", businessIso = "") {
  lines.forEach((line) => {
    const p = bj01Products.find((x) => x.id === line.productRef);
    if (!p) return;
    const parts = p.tracking === "LOT" && line.lots?.length ? line.lots : [{ code: "", ...line }];
    parts.forEach((part) => [["Bán được", part.accepted], ["Cách ly", part.quarantine], ["Hỏng", part.damaged]].forEach(([state, qty]) => {
      if (qty > 0) t7Ledger.post({ key: `UIF-02:${ref}:${p.id}:${part.code}:${state}`, productId: p.id, lot: part.code, kind: "Nhận hàng", doc: ref, delta: qty, state, sourceFlow: "UIF-02", note, businessIso, at: { expiry: part.expiry } });
    }));
  });
}

// ---- Sự kiện
// Khung web, SCR-001: chọn dòng = đổi chi tiết bên phải (không đổi trang); focus về dòng vừa chọn để đi tiếp bằng bàn phím.
function bj01SelectWebProduct(id) {
  bj01WebSelectedId=id; bj01SelectedProductId=id;
  renderAppScreen();
  document.querySelector(`tr[data-bj01-product="${CSS.escape(id)}"] .k7-row-open`)?.focus({ preventScroll: true });
}
// Esc đóng sheet đang mở (lô, nguồn, quét): core.js lo Esc và vòng Tab.
onDialogClose["UIF-01"] = () => {
  if (!(bj01LotOpen || bj01ProvenanceOpen || bj01ScanOpen)) return false;
  bj01LotOpen = false; bj01ProvenanceOpen = false; bj01ScanOpen = false; renderAppScreen(); return true;
};
document.addEventListener("click", (event) => {
  if (activeFlowId === "UIF-01") {
    const product = event.target.closest("[data-bj01-product]");
    if (product) {
      bj01SelectedProductId=product.dataset.bj01Product; bj01LotOpen=false; bj01ProvenanceOpen=false;
      if (viewport==="web" && activeScreenId==="SCR-001") return bj01SelectWebProduct(bj01SelectedProductId);
      return navigate("SCR-003");
    }
    if (event.target.closest("[data-bj01-scan]")) { bj01ScanOpen=true; return renderAppScreen(); }
    if (event.target.matches("[data-bj01-scan-close]")) { bj01ScanOpen=false; return renderAppScreen(); }
    const sample = event.target.closest("[data-bj01-scan-sample]");
    if (sample) {
      bj01ScanOpen=false; bj01SelectedProductId=sample.dataset.bj01ScanSample; bj01LotOpen=false; bj01ProvenanceOpen=false;
      if (viewport==="web" && activeScreenId==="SCR-001") return bj01SelectWebProduct(bj01SelectedProductId);
      return navigate("SCR-003");
    }
    if (event.target.closest("[data-bj01-set-threshold]")) { bj01LotOpen=false; bj01ProvenanceOpen=false; return capOpenForProduct(bj01SelectedProductId); }
    if (event.target.closest("[data-bj01-receive]")) {
      // Mở Nhận hàng với ô tìm điền sẵn tên sản phẩm: chứng từ đang chờ có sản phẩm này hiện ra trước, nhập nhanh ở cuối danh sách.
      const product = bj01ProductById(bj01SelectedProductId);
      bj01LotOpen=false; bj01ProvenanceOpen=false;
      activeFlowId="UIF-02"; flowMode="quick"; resetBj02Receipt("quick"); bj02ResetFlowStates();
      activeScreenId="SCR-008"; stateByScreen["SCR-008"]="READY";
      syncReviewUrl(); return render();
    }
    const dispose = event.target.closest("[data-bj01-dispose-lot]");
    if (dispose) {
      bj01LotOpen=false; bj01ProvenanceOpen=false;
      // v5.28.0: lô hết hạn được điều chỉnh giảm qua Kiểm kê (lý do "Hết hạn"), không còn luồng Tiêu hủy.
      return crSwitchFlow("UIF-08", "SCR-043", "READY");
    }
    const change = event.target.closest("[data-bj01-change-state]");
    if (change) {
      const t7 = bj01T7Lot(bj01ProductById(bj01SelectedProductId), change.dataset.bj01ChangeState);
      bj01LotOpen=false; bj01ProvenanceOpen=false;
      if (!t7) return renderAppScreen();
      k5SelectedLotId = t7.id; bj09ResetDraft(); bj09SetState("SCR-038", "READY"); bj09ReturnTo = "SCR-038";
      activeFlowId="UIF-09"; activeScreenId="SCR-038"; syncReviewUrl(); return render();
    }
    const lot = event.target.closest("[data-bj01-lot]");
    if (lot) { bj01SelectedLotCode=lot.dataset.bj01Lot; bj01LotOpen=true; bj01ProvenanceOpen=false; return renderAppScreen(); }
    const filter = event.target.closest("[data-bj01-filter]");
    if (filter) { bj01Filter=filter.dataset.bj01Filter; stateByScreen["SCR-001"]="READY"; return render(); }
    if (event.target.closest("[data-bj01-clear]")) { bj01Query=""; bj01Filter="ALL"; stateByScreen["SCR-001"]="READY"; return render(); }
    const receipt = event.target.closest("[data-bj01-open-receipt]");
    if (receipt) { bj01ProvenanceOpen=false; bj01LotOpen=false; return bj02OpenRecorded(receipt.dataset.bj01OpenReceipt, { flow: "UIF-01", screen: "SCR-003" }); }
    if (event.target.closest("[data-bj01-provenance]")) { bj01ProvenanceOpen=true; bj01LotOpen=false; return renderAppScreen(); }
    if (event.target.matches("[data-bj01-close-provenance]") || event.target.closest("button[data-bj01-close-provenance]")) { bj01ProvenanceOpen=false; return renderAppScreen(); }
    if (event.target.matches("[data-bj01-close-lot]") || event.target.closest("button[data-bj01-close-lot]")) { bj01LotOpen=false; return renderAppScreen(); }
    if (event.target.closest("[data-bj01-refresh]")) { bj01QueryAsOf=bj01RefreshSequence[Math.min(bj01RefreshIndex,bj01RefreshSequence.length-1)]; bj01RefreshIndex=Math.min(bj01RefreshIndex+1,bj01RefreshSequence.length-1); stateByScreen[activeScreenId]="READY"; render(); return showToast("Đã cập nhật tồn kho","success"); }
    if (event.target.closest("[data-bj01-handoff]")) {
      bj01ProvenanceOpen=false; bj01LotOpen=false; return bj15OpenCard({product:bj01SelectedProductId,entry:"bj01"});
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
