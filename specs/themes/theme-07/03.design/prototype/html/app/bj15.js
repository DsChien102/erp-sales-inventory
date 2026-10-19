/* BJ-15 — Báo cáo tồn và thẻ kho (UIF-15). Màn: SCR-054…059.
 *
 * Đã viết lại sạch (T7-P gói A9, 2026-10-18). Màn đăng ký qua flowRenderers / renderers.
 * Helper chung cf* / ac310ProductRow → app/shared-control.js.
 * SCR-056 dùng chung với BJ-09 qua flowRenderers.
 */

let cf15ReportType = "INVENTORY";
let cf15DateMode = "BUSINESS";
let cf15Warehouse = "MAIN";
let cf15Product = "ALL";
let cf15From = "2026-09-01";
let cf15To = "2026-09-07";
let cf15SelectedProduct = "P-NOB";
let cf15SelectedMovement = "M-RECEIPT";
let cf15ProductSheetOpen = false;
let cf15ExportFrom = "REPORT";
let cf15FinanceIncluded = true;
const cf15Products = [
  {id:"P-NOB",name:"Nobivac DHPPi",code:"SP-00418",qty:118,uom:"hộp",available:106,value:10030000,tracking:"LOT",lots:[{lot:"N2407-01",qty:70,state:"Bán được"},{lot:"N2408-02",qty:36,state:"Bán được"},{lot:"N2407-Q",qty:12,state:"Cách ly"}]},
  {id:"P-AMX",name:"Amox 500",code:"SP-00128",qty:24,uom:"hộp",available:18,value:3480000,tracking:"LOT",lots:[{lot:"L2407-A",qty:18,state:"Bán được"},{lot:"L2407-Q",qty:6,state:"Cách ly"}]},
  {id:"P-GLV",name:"Găng tay M",code:"SP-00602",qty:34,uom:"hộp",available:34,value:2550000,tracking:"NONE",lots:[]}
];
/* productId + MV-AMX-01 / MV-GLV-01 đã ghi sẵn (trước đây v350 gắn lúc nạp). */
const cf15Movements = [
  {id:"M-RECEIPT",productId:"P-NOB",time:"07/09/2026 · 09:14",business:"07/09/2026",recorded:"07/09/2026 · 09:16",label:"Nhận hàng",source:"Phiếu nhận PN-260907-04",delta:20,before:98,after:118,uom:"hộp",lot:"N2408-02",state:"Bán được",actor:"Nguyễn An",value:1700000},
  {id:"M-SALE",productId:"P-NOB",time:"06/09/2026 · 15:40",business:"06/09/2026",recorded:"06/09/2026 · 15:42",label:"Bán hàng",source:"Đơn bán DH-260906-118",delta:-4,before:102,after:98,uom:"hộp",lot:"N2407-01",state:"Bán được",actor:"Trần Minh",value:-340000},
  {id:"M-STATUS",productId:"P-NOB",time:"05/09/2026 · 10:05",business:"05/09/2026",recorded:"05/09/2026 · 10:05",label:"Chuyển tình trạng",source:"Yêu cầu trạng thái TT-260905-03",delta:0,before:102,after:102,uom:"hộp",lot:"N2407-Q",state:"Cách ly",actor:"Lê Hoa",value:0},
  {id:"MV-AMX-01",productId:"P-AMX",label:"Nhận hàng",source:"PN-260907-11",business:"07/09/2026",recorded:"07/09/2026",actor:"Nguyễn An",before:12,delta:6,after:18,uom:"hộp",lot:"L2407-A",state:"Bán được",value:720000},
  {id:"MV-GLV-01",productId:"P-GLV",label:"Kiểm kê",source:"KK-0709-03",business:"07/09/2026",recorded:"07/09/2026",actor:"Nguyễn An",before:5,delta:1,after:6,uom:"hộp",lot:"L2405-M",state:"Bán được",value:0}
];

function cf15ProductById(id){return cf15Products.find(x=>x.id===id)||cf15Products[0];}
function cf15Movement(){return cf15Movements.find(x=>x.id===cf15SelectedMovement)||cf15Movements[0];}
function cf15DateLabel(mode=cf15DateMode){return mode==="RECORDED"?"Ngày ghi nhận":"Ngày nghiệp vụ";}
function bj15DateIso(v){const m=String(v||"").match(/^(\d{2})\/(\d{2})\/(\d{4})/);return m?`${m[3]}-${m[2]}-${m[1]}`:String(v||"").slice(0,10);}
function bj15Products(){return cf15Product==="ALL"?cf15Products:cf15Products.filter(p=>p.id===cf15Product);}
function bj15Movements(mode=cf15DateMode){
  const pid=cf15Product==="ALL"?cf15SelectedProduct:cf15Product;
  return cf15Movements.filter(m=>(!pid||m.productId===pid)).filter(m=>{
    const d=bj15DateIso(mode==="RECORDED"?m.recorded:m.business);
    return (!cf15From||d>=cf15From)&&(!cf15To||d<=cf15To);
  });
}
function bj15Minus(text){
  const v=String(text??"");
  return /^-\s?\d/.test(v)?v.replace(/^-\s?/,"−"):v;
}
function bj15Segmented(value,items,attr){
  return `<div class="cf-segmented" data-ds-component="VSegmentedControl">${items.map(([v,l])=>`<button type="button" class="cf-segment ${value===v?"is-selected":""}" ${attr}="${v}" data-ds-component="VSegmentedControlItem">${l}</button>`).join("")}</div>`;
}
function bj15ModeChoice(value,label,detail,current,attr){
  return `<button type="button" class="ac310-mode-row${current===value?" is-selected":""}" ${attr}="${value}" data-ds-component="VRadio" data-figma-node="522:7410"><span class="ac310-radio-control"></span><span class="ac310-radio-copy"><strong>${esc(label)}</strong><small>${esc(detail)}</small></span></button>`;
}
function bj15ContextBanner(state,mode){
  const stale=state==="STALE"?vBanner("warning","Dữ liệu đang cập nhật","Dùng mốc dữ liệu bên dưới; không sửa tồn kho từ số liệu chưa cập nhật."):"";
  return `${stale}<div class="cf-context-row"><span>${cf15DateLabel(mode)} · ${cfDateVN(cf15From)} → ${cfDateVN(cf15To)}</span><strong>Đến 07/09/2026 · 11:00</strong></div>`;
}
function bj15ExitReport(){
  return primaryFooter("Về báo cáo",'data-v360-action="fallback-exit" data-v360-target="SCR-055"');
}
function bj15ProductSheet(product,financeAllowed){
  if(!cf15ProductSheetOpen||!product) return "";
  const rows=[["Tồn vật lý",`${cfNumber(product.qty)} ${product.uom}`,true],["Khả dụng bán",`${cfNumber(product.available)} ${product.uom}`,true],...(financeAllowed?[["Giá trị tồn",cfMoney(product.value)]]:[])];
  const lots=product.tracking==="LOT"?product.lots.map((l)=>ac310RecordRow({title:`Lô ${l.lot}`,subtitle:`${l.qty} ${product.uom}`,badge:l.state,tone:l.state==="Bán được"?"Success":"Warning",status:true,leading:null})).join(""):"";
  return `<div class="sheet-backdrop" data-cf15-action="close-product-sheet"><section class="bottom-sheet ac310-sheet" data-ds-component="VBottomSheet" data-figma-node="4695:6353" role="dialog" aria-modal="true" onclick="event.stopPropagation()"><div class="sheet-handle"></div><div class="sheet-title"><h3>${esc(product.name)}</h3><small>${esc(product.code)}</small></div><div class="sheet-content">${ac310KeyValueSurface("",rows,{extraClass:"ac310-sheet-surface"})}${product.tracking==="LOT"?`${ac310SectionTitle("Theo lô")}${ac310ListSurface(lots,"ac310-sheet-list")}`:`<p class="ac310-note">Sản phẩm không quản lý theo lô.</p>`}<div class="sheet-actions t381-single-business-action"><button class="button button--primary" type="button" data-cf15-action="product-stock-card" data-cf15-product-id="${product.id}">Xem thẻ kho</button></div></div></section></div>`;
}
function bj15LegacyProductSheet(product,financeAllowed){
  if(!cf15ProductSheetOpen)return "";
  const stateRows=[...new Set(product.lots.map(x=>x.state))].map(st=>[st,`${cfNumber(product.lots.filter(x=>x.state===st).reduce((a,x)=>a+x.qty,0))} ${product.uom}`]);
  const lotBlock=product.tracking==="LOT"?`${ioSectionTitle("Theo lô")}<div class="cf-sheet-list">${product.lots.map(x=>ioMetaRow(`Lô ${x.lot}`,`${cfNumber(x.qty)} ${product.uom} · ${x.state}`,true)).join("")}</div>`:"";
  const stateBlock=stateRows.length?`${ioSectionTitle("Theo tình trạng")}<div class="cf-sheet-list">${stateRows.map(r=>ioMetaRow(r[0],r[1],true)).join("")}</div>`:"";
  return `<div class="sheet-backdrop" data-cf15-action="close-product-sheet"><section class="bottom-sheet cf15-sheet" role="dialog" aria-modal="true" aria-label="Chi tiết ${product.name}" onclick="event.stopPropagation()" data-ds-component="VBottomSheet" data-figma-node="4695:6353"><div class="sheet-handle"></div><div class="sheet-title"><h3>${product.name}</h3><small>${product.code}</small></div><div class="sheet-divider"></div><div class="sheet-content">${crFactCard("Số lượng",[["Tồn vật lý",`${cfNumber(product.qty)} ${product.uom}`,true],["Khả dụng bán",`${cfNumber(product.available)} ${product.uom}`,true],...(financeAllowed?[["Giá trị tồn",cfMoney(product.value)]]:[])])}${stateBlock}${lotBlock}${product.tracking!=="LOT"?'<p class="io-footnote">Sản phẩm không quản lý theo lô; báo cáo không tạo một “lô mặc định” giả.</p>':""}<div class="sheet-actions t381-single-business-action"><button class="button button--primary" type="button" data-cf15-action="product-stock-card" data-cf15-product-id="${product.id}" data-ds-component="VButton">Xem thẻ kho</button></div></div></section></div>`;
}
function bj15LegacyInventoryBody(state,mode){
  const financeAllowed=state!=="FINANCIAL_RESTRICTED",products=bj15Products();
  if(!products.length)return `${bj15ContextBanner(state,mode)}${ioEmpty("Không có dữ liệu phù hợp","Đổi phạm vi hoặc kỳ báo cáo để kiểm tra lại.")}`;
  const rows=products.map(p=>ioProductRow({name:p.name,code:p.code,primary:`${cfNumber(p.qty)} ${p.uom}`,secondary:`Khả dụng ${cfNumber(p.available)} ${p.uom}`,attr:`data-cf15-product-row="${p.id}"`})).join("");
  const totalValue=products.reduce((a,x)=>a+x.value,0);
  return `${bj15ContextBanner(state,mode)}${cfSummaryGrid([["Sản phẩm",products.length],["Kho","Kho trung tâm"],...(financeAllowed?[["Tổng giá trị",cfMoney(totalValue)]]:[])])}${financeAllowed?"":vBanner("info","Giá trị tài chính đã được ẩn","Bạn vẫn có thể xem số lượng trong phạm vi được cấp quyền.")}<div class="io-list-card" data-ds-component="VSection" data-composed-from="DS v2 / List Row"><div class="io-product-list">${rows}</div></div><p class="io-footnote">Không cộng các số lượng khác đơn vị thành một tổng giả.</p><div class="cf-inline-actions">${cfSecondary("Xuất báo cáo",'data-cf15-action="export"')}</div>${bj15LegacyProductSheet(cf15ProductById(cf15SelectedProduct),financeAllowed)}`;
}
function bj15LegacyStockCardBody(state,mode){
  const financeAllowed=state!=="FINANCIAL_RESTRICTED";
  const p=cf15ProductById(cf15Product==="ALL"?cf15SelectedProduct:cf15Product);
  const movements=bj15Movements(mode);
  const movRows=movements.map(m=>`<button class="cf-movement-row" type="button" data-cf15-movement="${m.id}" data-ds-component="DS v2 / List Row"><span><strong>${m.label}</strong><small>${mode==="RECORDED"?m.recorded:m.business} · ${m.source}</small></span><span class="cf-movement-values"><strong>${m.delta>0?"+":""}${m.delta} ${m.uom}</strong><small>Còn ${m.after} ${m.uom}</small></span>${navChevron()}</button>`).join("");
  return `${bj15ContextBanner(state,mode)}${crFactCard(p.name,[["Mã",p.code,true],["Tồn hiện tại",`${cfNumber(p.qty)} ${p.uom}`],["Khả dụng bán",`${cfNumber(p.available)} ${p.uom}`],...(financeAllowed?[["Giá trị tồn",cfMoney(p.value)]]:[])])}${financeAllowed?"":vBanner("info","Giá trị tài chính đã được ẩn","Thẻ kho vẫn hiển thị số lượng và nguồn nghiệp vụ trong phạm vi quyền.")}${movements.length?`<div class="cf-movement-list">${movRows}</div>`:ioEmpty("Không có biến động trong kỳ","Đổi khoảng ngày hoặc sản phẩm để xem dữ liệu khác.")}<div class="cf-inline-actions">${cfSecondary("Xuất thẻ kho",'data-cf15-action="export"')}</div>`;
}

function render054BJ15(state){
  if(state==="PERMISSION_DENIED") return ac310SanitizeMarkup(appShell({title:"Tra cứu kho",body:deniedBody(),centered:true,back:false}));
  if(state==="CONFLICT") return ac310SanitizeMarkup(appShell({title:"Tra cứu kho",body:vBanner("warning","Phạm vi vừa thay đổi","Tải lại phạm vi tra cứu trước khi xem báo cáo."),back:false}));
  if(["READY","VALIDATION_ERROR"].includes(state)){
    const invalid=state==="VALIDATION_ERROR";
    const productOptions=[["ALL","Tất cả sản phẩm"],...cf15Products.map((x)=>[x.id,`${x.name} · ${x.code}`])];
    const modes=`${bj15ModeChoice("INVENTORY","Tồn kho","Xem số lượng và giá trị theo phạm vi",cf15ReportType,"data-cf15-report-type")}${bj15ModeChoice("STOCK_CARD","Thẻ kho","Xem biến động của một sản phẩm",cf15ReportType,"data-cf15-report-type")}`;
    const dates=`${bj15ModeChoice("BUSINESS","Ngày nghiệp vụ","Theo ngày nghiệp vụ phát sinh",cf15DateMode,"data-cf15-date-mode")}${bj15ModeChoice("RECORDED","Ngày ghi nhận","Theo thời điểm hệ thống ghi nhận",cf15DateMode,"data-cf15-date-mode")}`;
    const body=`${invalid?vBanner("error","Chưa đủ điều kiện tra cứu",cf15ReportType==="STOCK_CARD"?"Chọn một sản phẩm cụ thể để xem thẻ kho.":"Kiểm tra lại phạm vi và kỳ báo cáo."):""}${ac310RadioSurface("Loại tra cứu",[modes])}<div class="ac310-form-stack">${cfSelect("Kho",cf15Warehouse,[["MAIN","Kho trung tâm"]],"data-cf15-warehouse","")}${cfSelect("Sản phẩm",cf15Product,productOptions,"data-cf15-product",cf15ReportType==="STOCK_CARD"?"Bắt buộc khi xem thẻ kho.":"")}</div>${ac310RadioSurface("Cách hiểu thời gian",[dates])}<div class="ac310-form-stack ac310-date-grid">${cfField("Từ ngày",cf15From,'data-cf15-from','date')}${cfField("Đến ngày",cf15To,'data-cf15-to','date')}</div>`;
    return ac310SanitizeMarkup(appShell({title:"Tra cứu kho",body,actions:primaryFooter("Xem báo cáo",'data-cf15-action="query"'),back:false}));
  }
  const productOptions=[["ALL","Tất cả sản phẩm"],...cf15Products.map(x=>[x.id,`${x.name} · ${x.code}`])];
  const body=`${ioSectionTitle("Loại tra cứu")}${bj15Segmented(cf15ReportType,[["INVENTORY","Tồn kho"],["STOCK_CARD","Thẻ kho"]],"data-cf15-report-type")}${ioSectionTitle("Phạm vi")}<div class="form-stack">${cfSelect("Kho",cf15Warehouse,[["MAIN","Kho trung tâm"]],"data-cf15-warehouse","Nếu tổ chức chỉ có một kho hợp lệ, hệ thống giữ sẵn kho đó.")}${cfSelect("Sản phẩm",cf15Product,productOptions,"data-cf15-product",cf15ReportType==="STOCK_CARD"?"Bắt buộc khi xem thẻ kho.":"Có thể để tất cả khi xem báo cáo tồn.")}</div>${ioSectionTitle("Cách hiểu thời gian")}${bj15Segmented(cf15DateMode,[["BUSINESS","Ngày nghiệp vụ"],["RECORDED","Ngày ghi nhận"]],"data-cf15-date-mode")}<p class="io-footnote">Hai mốc thời gian có ý nghĩa khác nhau và không được trộn âm thầm trong cùng một kết quả.</p><div class="form-stack cf-date-grid">${cfField("Từ ngày",cf15From,'data-cf15-from','date')}${cfField("Đến ngày",cf15To,'data-cf15-to','date')}</div>`;
  return ac310SanitizeMarkup(appShell({title:"Tra cứu kho",body,actions:primaryFooter("Xem báo cáo",'data-cf15-action="query"'),back:false}));
}

function render055BJ15(state){
  if(state==="PERMISSION_DENIED") return ac310SanitizeMarkup(appShell({title:"Kết quả tra cứu",body:deniedBody(),centered:true}));
  if(state==="LOADING") return ac310SanitizeMarkup(appShell({title:"Kết quả tra cứu",body:loadingBody()}));
  if(state==="EMPTY"||state==="FILTER_EMPTY") return ac310SanitizeMarkup(appShell({title:"Kết quả tra cứu",body:ioEmpty(state==="FILTER_EMPTY"?"Không có dữ liệu phù hợp":"Chưa có dữ liệu tồn kho","Đổi phạm vi hoặc kỳ báo cáo để kiểm tra lại.")}));
  const mode=state==="RECORDED_DATE_VIEW"?"RECORDED":state==="BUSINESS_DATE_VIEW"?"BUSINESS":cf15DateMode;
  if(state==="STALE"||state==="ARCHIVED_DATA"){
    const body=cf15ReportType==="STOCK_CARD"?bj15LegacyStockCardBody(state,mode):bj15LegacyInventoryBody(state,mode);
    return ac310SanitizeMarkup(appShell({title:cf15ReportType==="STOCK_CARD"?"Thẻ kho":"Báo cáo tồn kho",subtitle:`Kho trung tâm · ${cf15DateLabel(mode)}`,body}));
  }
  if(["READY","RECORDED_DATE_VIEW","BUSINESS_DATE_VIEW","FINANCIAL_RESTRICTED"].includes(state)){
    const financeAllowed=state!=="FINANCIAL_RESTRICTED";
    if(cf15ReportType==="INVENTORY"){
      const products=bj15Products();
      if(!products.length) return ac310SanitizeMarkup(appShell({title:"Báo cáo tồn kho",body:ioEmpty("Không có dữ liệu phù hợp","Đổi phạm vi hoặc kỳ báo cáo để kiểm tra lại.")}));
      const rows=products.map((p)=>ac310ProductRow({name:p.name,code:p.code,meta:`${cfNumber(p.qty)} ${p.uom} · Khả dụng ${cfNumber(p.available)} ${p.uom}`,attrs:`data-cf15-product-row="${p.id}"`})).join("");
      const totalValue=products.reduce((a,x)=>a+x.value,0);
      const body=`${bj15ContextBanner(state,mode)}${ac310SummaryMetrics([["Sản phẩm",products.length],["Kho","Kho trung tâm"],...(financeAllowed?[["Tổng giá trị",cfMoney(totalValue)]]:[])])}${financeAllowed?"":vBanner("info","Giá trị tài chính đã được ẩn","Bạn vẫn có thể xem số lượng trong phạm vi được cấp quyền.")}${ac310ListSurface(rows)}<button class="button button--secondary ac310-inline-button" type="button" data-cf15-action="export">Xuất báo cáo</button>${bj15ProductSheet(cf15ProductById(cf15SelectedProduct),financeAllowed)}`;
      return ac310SanitizeMarkup(appShell({title:"Báo cáo tồn kho",subtitle:`Kho trung tâm · ${cf15DateLabel(mode)}`,body}));
    }
    const p=cf15ProductById(cf15Product==="ALL"?cf15SelectedProduct:cf15Product);
    const filtered=bj15Movements(mode);
    if(!filtered.length) return ac310SanitizeMarkup(appShell({title:"Thẻ kho",subtitle:`${p.name} · ${cf15DateLabel(mode)}`,body:`${bj15ContextBanner(state,mode)}${ioEmpty("Không có biến động trong kỳ","Đổi khoảng ngày hoặc sản phẩm để xem dữ liệu khác.")}`}));
    const movements=filtered.map((m)=>ac310RecordRow({title:m.label,subtitle:`${mode==="RECORDED"?m.recorded:m.business} · ${m.source}`,badge:`${m.delta>0?"+":""}${m.delta} ${m.uom}`,tone:"Neutral",attrs:`data-cf15-movement="${m.id}"`,leading:null})).join("");
    const body=`${bj15ContextBanner(state,mode)}${ac310ProductRow({name:p.name,code:p.code,meta:`${cfNumber(p.qty)} ${p.uom}`,badge:`Khả dụng ${cfNumber(p.available)} ${p.uom}`,tone:"Success",status:true})}${financeAllowed?ac310KeyValueSurface("",[["Giá trị tồn",cfMoney(p.value),true]]):vBanner("info","Giá trị tài chính đã được ẩn","Thẻ kho vẫn hiển thị số lượng và nguồn nghiệp vụ.")}${ac310SectionTitle("Biến động")}${ac310ListSurface(movements)}<button class="button button--secondary ac310-inline-button" type="button" data-cf15-action="export">Xuất thẻ kho</button>`;
    return ac310SanitizeMarkup(appShell({title:"Thẻ kho",subtitle:`${p.name} · ${cf15DateLabel(mode)}`,body}));
  }
  const body=cf15ReportType==="STOCK_CARD"?bj15LegacyStockCardBody(state,mode):bj15LegacyInventoryBody(state,mode);
  return ac310SanitizeMarkup(appShell({title:cf15ReportType==="STOCK_CARD"?"Thẻ kho":"Báo cáo tồn kho",subtitle:`Kho trung tâm · ${cf15DateLabel(mode)}`,body}));
}

function render056BJ15(state){
  if(["READY","FINANCIAL_RESTRICTED","LOCKED"].includes(state)){
    const m=cf15Movement(),financeAllowed=state!=="FINANCIAL_RESTRICTED";
    const lockedNotice=state==="LOCKED"?vBanner("info","Dữ liệu đang ở chế độ chỉ đọc","Bạn có thể xem nguồn và truy vết; màn này không thay đổi dữ liệu."):"";
    const deltaLabel=bj15Minus(`${m.delta>0?"+":""}${m.delta} ${m.uom}`);
    const body=`${lockedNotice}${ac310RecordRow({title:m.label,subtitle:m.source,badge:deltaLabel,tone:"Neutral",status:true,leading:null})}${ac310InfoSurface("Thời gian và người thực hiện",[["Ngày nghiệp vụ",m.business],["Ngày ghi nhận",m.recorded],["Người thực hiện",m.actor]])}${ac310KeyValueSurface("Số lượng",[["Trước",`${m.before} ${m.uom}`],["Biến động",deltaLabel,true],["Sau",`${m.after} ${m.uom}`],["Lô",m.lot],["Tình trạng",m.state]])}${financeAllowed?ac310KeyValueSurface("Giá trị",[["Tác động",bj15Minus(cfMoney(m.value)),true]]):vBanner("info","Giá trị tài chính đã được ẩn","Bạn vẫn có thể truy vết nguồn và số lượng.")}<button class="button button--secondary ac310-inline-button" type="button" data-cf15-action="source">Xem nguồn</button>`;
    return ac310SanitizeMarkup(appShell({title:"Chi tiết biến động",body,backAction:"v351-cf15-movement-back"}));
  }
  if(state==="PERMISSION_DENIED") return ac310SanitizeMarkup(appShell({title:"Chi tiết biến động",body:deniedBody(),centered:true,backAction:"v351-cf15-movement-back"}));
  if(state==="LOADING") return ac310SanitizeMarkup(appShell({title:"Chi tiết biến động",body:loadingBody(),backAction:"v351-cf15-movement-back"}));
  if(state==="CONFLICT") return ac310SanitizeMarkup(appShell({title:"Chi tiết biến động",body:vBanner("warning","Nguồn nghiệp vụ vừa thay đổi","Tải lại dữ liệu trước khi dựa vào chi tiết đang xem."),backAction:"v351-cf15-movement-back"}));
  const m=cf15Movement(); const financeAllowed=state!=="FINANCIAL_RESTRICTED";
  const body=`${crFactCard(m.label,[["Nguồn",m.source,true],["Ngày nghiệp vụ",m.business],["Ngày ghi nhận",m.recorded],["Người thực hiện",m.actor]])}${crFactCard("Số lượng",[["Trước",`${m.before} ${m.uom}`],["Biến động",bj15Minus(`${m.delta>0?"+":""}${m.delta} ${m.uom}`),true],["Sau",`${m.after} ${m.uom}`],["Lô",m.lot],["Tình trạng",m.state]])}${financeAllowed?crFactCard("Giá trị",[["Tác động",bj15Minus(cfMoney(m.value)),true],["Nguồn giá","Giá trị chính thức của giao dịch"]]):vBanner("info","Giá trị tài chính đã được ẩn","Bạn có thể truy vết nguồn và số lượng nhưng không xem giá trị.")}${cfSecondary("Xem nguồn",'data-cf15-action="source"')}`;
  return ac310SanitizeMarkup(appShell({title:"Chi tiết biến động",body,backAction:"v351-cf15-movement-back"}));
}

function render057BJ15(state){
  if(state==="READY"||state==="STALE"){
    const m=cf15Movement();
    const items=[ac310AuditItem("Create",m.source,`Nghiệp vụ nguồn hoàn tất · ${m.business}`),ac310AuditItem("System","Đã ghi nhận kho",m.recorded),ac310AuditItem("Update",`${m.delta>=0?"Tồn tăng":"Tồn giảm"} ${Math.abs(m.delta)} ${m.uom}`,`Số dư sau biến động: ${m.after} ${m.uom}`)];
    const body=`${state==="STALE"?vBanner("warning","Dữ liệu nguồn đang cập nhật","Giữ mốc hiển thị hiện tại cho tới khi tải lại dữ liệu."):""}${ac310InfoSurface("Biến động đang xem",[["Nguồn",m.source,true],["Sản phẩm",cf15ProductById(cf15Product==="ALL"?cf15SelectedProduct:cf15Product).name],["Số lượng",bj15Minus(`${m.delta>0?"+":""}${m.delta} ${m.uom}`)]])}${ac310AuditSurface("",items)}<button class="button button--secondary ac310-inline-button" type="button" data-cf15-action="export-source">Xuất bằng chứng</button>`;
    return ac310SanitizeMarkup(appShell({title:"Nguồn nghiệp vụ",body,backAction:"v351-cf15-source-back"}));
  }
  if(state==="PERMISSION_DENIED") return ac310SanitizeMarkup(appShell({title:"Nguồn nghiệp vụ",body:deniedBody(),centered:true,backAction:"v351-cf15-source-back"}));
  if(state==="LOADING") return ac310SanitizeMarkup(appShell({title:"Nguồn nghiệp vụ",body:loadingBody(),backAction:"v351-cf15-source-back"}));
  if(state==="EMPTY") return ac310SanitizeMarkup(appShell({title:"Nguồn nghiệp vụ",body:ioEmpty("Chưa có bằng chứng nguồn","Không có chuỗi nguồn phù hợp với biến động đang xem."),backAction:"v351-cf15-source-back"}));
  const m=cf15Movement();
  const body=`${crFactCard("Biến động đang xem",[["Nguồn",m.source,true],["Sản phẩm",cf15ProductById(cf15Product==="ALL"?cf15SelectedProduct:cf15Product).name],["Số lượng",bj15Minus(`${m.delta>0?"+":""}${m.delta} ${m.uom}`)]])}${ioSectionTitle("Dòng thời gian nghiệp vụ")}<div class="timeline cf-business-timeline"><div class="timeline-card"><strong>${m.source}</strong><small>Giao dịch nguồn được hoàn tất</small></div><div class="timeline-card"><strong>Đã ghi nhận kho</strong><small>${m.recorded}</small></div><div class="timeline-card"><strong>${m.delta>=0?"Tồn tăng":"Tồn giảm"} ${Math.abs(m.delta)} ${m.uom}</strong><small>Số dư sau biến động: ${m.after} ${m.uom}</small></div></div><div class="cf-inline-actions">${cfSecondary("Xuất bằng chứng",'data-cf15-action="export-source"')}</div>`;
  return ac310SanitizeMarkup(appShell({title:"Nguồn nghiệp vụ",body,backAction:"v351-cf15-source-back"}));
}

function render058BJ15(state){
  if(state==="PERMISSION_DENIED") return ac310SanitizeMarkup(appShell({title:"Xuất báo cáo",body:deniedBody(),centered:true,back:false,actions:bj15ExitReport()}));
  if(state==="EXPORT_RUNNING") return ac310SanitizeMarkup(appShell({title:"Xuất báo cáo",body:loadingBody(),centered:true,back:false}));
  if(state==="VALIDATION_ERROR") return ac310SanitizeMarkup(appShell({title:"Xuất báo cáo",body:vBanner("error","Chưa thể xuất","Phạm vi hoặc mốc dữ liệu không còn hợp lệ. Quay lại kết quả tra cứu để kiểm tra."),backAction:"cf15-back-export"}));
  if(state==="STALE") return ac310SanitizeMarkup(appShell({title:"Xuất báo cáo",body:`${vBanner("warning","Kết quả đang cập nhật","Không xuất một file được hiểu nhầm là số liệu mới hơn mốc đang hiển thị.")}${crFactCard("Mốc dữ liệu",[["Đến","07/09/2026 · 11:00",true],["Cách hiểu thời gian",cf15DateLabel()]])}`,backAction:"cf15-back-export"}));
  if(state==="READY"){
    const sourceLabel=cf15ExportFrom==="SOURCE"?"Bằng chứng biến động":cf15ReportType==="STOCK_CARD"?"Thẻ kho":"Báo cáo tồn kho";
    const productLabel=cf15Product==="ALL"?"Tất cả sản phẩm":cf15ProductById(cf15Product).name;
    const count=cf15ReportType==="STOCK_CARD"?bj15Movements(cf15DateMode).length:bj15Products().length;
    const body=`${crFactCard("Phạm vi xuất",[["Nội dung",sourceLabel,true],["Kho","Kho trung tâm"],["Sản phẩm",productLabel],["Kỳ",`${cfDateVN(cf15From)} → ${cfDateVN(cf15To)}`],["Cách hiểu thời gian",cf15DateLabel()],["Số dòng trong phạm vi",String(count)],["Giá trị tài chính",cf15FinanceIncluded?"Có":"Không"]])}${crFactCard("Định dạng",[["Tệp","CSV",true],["Quyền dữ liệu","Giữ đúng như màn đang xem"]])}<p class="io-footnote">Tệp xuất giữ đúng bộ lọc, khoảng ngày, quyền và mốc dữ liệu của kết quả đang xem.</p>`;
    return appShell({title:"Xuất báo cáo",body,actions:primaryFooter("Xuất báo cáo",'data-cf15-action="confirm-export"'),backAction:"cf15-back-export"});
  }
  const sourceLabel=cf15ExportFrom==="SOURCE"?"Bằng chứng biến động":cf15ReportType==="STOCK_CARD"?"Thẻ kho":"Báo cáo tồn kho";
  const body=`${crFactCard("Phạm vi xuất",[["Nội dung",sourceLabel,true],["Kho","Kho trung tâm"],["Kỳ",`${cfDateVN(cf15From)} → ${cfDateVN(cf15To)}`],["Cách hiểu thời gian",cf15DateLabel()],["Dữ liệu đến","07/09/2026 · 11:00"],["Giá trị tài chính",cf15FinanceIncluded?"Có":"Không"]])}${crFactCard("Định dạng",[["Tệp","CSV",true],["Quyền dữ liệu","Giữ đúng như màn đang xem"]])}<p class="io-footnote">Tệp xuất giữ cùng phạm vi, quyền và mốc dữ liệu với kết quả đang xem.</p>`;
  return ac310SanitizeMarkup(appShell({title:"Xuất báo cáo",body,actions:primaryFooter("Xuất báo cáo",'data-cf15-action="confirm-export"'),backAction:"cf15-back-export"}));
}

function render059BJ15(state){
  if(state==="PERMISSION_DENIED") return ac310SanitizeMarkup(appShell({title:"Kết quả xuất báo cáo",body:deniedBody(),centered:true,back:false,actions:bj15ExitReport()}));
  if(state==="PROCESSING") return ac310SanitizeMarkup(appShell({title:"Kết quả xuất báo cáo",body:loadingBody(),centered:true,back:false}));
  if(state==="SOURCE_STALE") return ac310SanitizeMarkup(appShell({title:"Kết quả xuất báo cáo",body:ioResult("Nguồn dữ liệu đã thay đổi","Không tạo tệp từ kết quả chưa cập nhật. Quay lại báo cáo và tải mốc hiện hành trước khi xuất lại.",[["Tệp","Chưa tạo"],["Dữ liệu","Không bị thay đổi"]],"warning"),actions:primaryFooter("Quay lại báo cáo",'data-cf15-action="done-export"'),centered:true,back:false}));
  if(state==="REJECTED_EXECUTION") return ac310SanitizeMarkup(appShell({title:"Kết quả xuất báo cáo",body:ioResult("Chưa tạo được tệp","Chưa tạo được tệp nhưng dữ liệu tồn kho không thay đổi.",[["Dữ liệu kho","Không thay đổi"],["Có thể thử lại","Từ cùng báo cáo hiện hành"]],"warning"),actions:primaryFooter("Quay lại báo cáo",'data-cf15-action="done-export"'),centered:true,back:false}));
  const filename=cf15ExportFrom==="SOURCE"?"bang-chung-bien-dong-07092026.csv":cf15ReportType==="STOCK_CARD"?"the-kho-07092026.csv":"bao-cao-ton-kho-07092026.csv";
  const body=ioResult("Đã tạo tệp báo cáo","Tệp giữ đúng phạm vi, quyền và mốc dữ liệu của kết quả đã xem.",[["Tệp",filename],["Dữ liệu đến","07/09/2026 · 11:00"],["Giá trị tài chính",cf15FinanceIncluded?"Có":"Không"]]);
  return ac310SanitizeMarkup(appShell({title:"Kết quả xuất báo cáo",body,actions:primaryFooter("Xong",'data-cf15-action="done-export"'),centered:true,back:false}));
}

Object.assign(renderers, {
  "SCR-054": render054BJ15,
  "SCR-055": render055BJ15,
  "SCR-057": render057BJ15,
  "SCR-058": render058BJ15,
  "SCR-059": render059BJ15
});
flowRenderers["UIF-15"] = Object.assign(flowRenderers["UIF-15"] || {}, {
  "SCR-056": render056BJ15
});
renderers["SCR-056"] = flowScreen("SCR-056");

document.addEventListener("input",(event)=>{
  if(activeFlowId!=="UIF-15") return;
  if(event.target.matches("[data-cf15-from]")){cf15From=event.target.value;return;}
  if(event.target.matches("[data-cf15-to]")){cf15To=event.target.value;return;}
},true);

document.addEventListener("change",(event)=>{
  if(activeFlowId!=="UIF-15") return;
  if(event.target.matches("[data-cf15-warehouse]")){cf15Warehouse=event.target.value;return;}
  if(event.target.matches("[data-cf15-product]")){cf15Product=event.target.value;if(cf15Product!=="ALL")cf15SelectedProduct=cf15Product;return;}
},true);

document.addEventListener("click",(event)=>{
  if(activeFlowId!=="UIF-15") return;
  const rt=event.target.closest("[data-cf15-report-type]"); if(rt){event.preventDefault();cf15ReportType=rt.dataset.cf15ReportType;if(cf15ReportType==="STOCK_CARD"&&cf15Product==="ALL"){cf15Product=cf15SelectedProduct;}stateByScreen["SCR-054"]="READY";return renderAppScreen();}
  const dm=event.target.closest("[data-cf15-date-mode]"); if(dm){event.preventDefault();cf15DateMode=dm.dataset.cf15DateMode;stateByScreen["SCR-054"]="READY";return renderAppScreen();}
  const pr=event.target.closest("[data-cf15-product-row]"); if(pr){event.preventDefault();cf15SelectedProduct=pr.dataset.cf15ProductRow;cf15ProductSheetOpen=true;return renderAppScreen();}
  const mv=event.target.closest("[data-cf15-movement]"); if(mv){event.preventDefault();cf15SelectedMovement=mv.dataset.cf15Movement;stateByScreen["SCR-056"]="READY";return navigate("SCR-056");}
  const action=event.target.closest("[data-cf15-action]"); if(action&&!action.disabled){
    event.preventDefault();event.stopPropagation();const k=action.dataset.cf15Action;
    if(k==="query"){
      if(!cf15From||!cf15To||cfDateKey(cf15From)>cfDateKey(cf15To)||(cf15ReportType==="STOCK_CARD"&&cf15Product==="ALL")){stateByScreen["SCR-054"]="VALIDATION_ERROR";return renderAppScreen();}
      cf15ProductSheetOpen=false;stateByScreen["SCR-055"]="READY";return navigate("SCR-055");
    }
    if(k==="close-product-sheet"){cf15ProductSheetOpen=false;return renderAppScreen();}
    if(k==="product-stock-card"){
      const id=action.dataset.cf15ProductId||cf15SelectedProduct;cf15ReportType="STOCK_CARD";cf15Product=id;cf15SelectedProduct=id;cf15ProductSheetOpen=false;stateByScreen["SCR-055"]="READY";return renderAppScreen();
    }
    if(k==="source"){stateByScreen["SCR-057"]="READY";return navigate("SCR-057");}
    if(k==="export"||k==="export-source"){
      cf15ExportFrom=k==="export-source"?"SOURCE":"REPORT";cf15FinanceIncluded=stateByScreen[activeScreenId]!=="FINANCIAL_RESTRICTED";stateByScreen["SCR-058"]="READY";return navigate("SCR-058");
    }
    if(k==="confirm-export"){
      stateByScreen["SCR-059"]="PROCESSING";navigate("SCR-059");window.setTimeout(()=>{if(activeFlowId==="UIF-15"&&activeScreenId==="SCR-059"&&stateByScreen["SCR-059"]==="PROCESSING"){stateByScreen["SCR-059"]="COMPLETED";render();}},320);return;
    }
    if(k==="done-export"){stateByScreen[cf15ExportFrom==="SOURCE"?"SCR-057":"SCR-055"]="READY";return navigate(cf15ExportFrom==="SOURCE"?"SCR-057":"SCR-055");}
  }
  const customBack=event.target.closest('[data-action="cf15-back-export"]');
  if(customBack){event.preventDefault();event.stopPropagation();return navigate(cf15ExportFrom==="SOURCE"?"SCR-057":"SCR-055");}
  const v351=event.target.closest("[data-action]");
  if(v351){
    const act=v351.dataset.action;
    if(act==="v351-cf15-movement-back"){event.preventDefault();event.stopImmediatePropagation();return navigate("SCR-055");}
    if(act==="v351-cf15-source-back"){event.preventDefault();event.stopImmediatePropagation();return navigate("SCR-056");}
  }
},true);


Object.assign(window.__VET45_QA__, {
  getCf15Rows(mode=typeof cf15DateMode!=="undefined"?cf15DateMode:"BUSINESS"){return (typeof bj15Movements==="function"?bj15Movements(mode):[]).map(x=>x.id);}
});
