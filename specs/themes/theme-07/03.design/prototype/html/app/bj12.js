/* BJ-12 — Khởi tạo tồn đầu kỳ (UIF-12). Màn: SCR-066, 067, 068, 070, 071 (SCR-069 đã gộp vào 068, T7-P bj12, 2026-10-21).
 *
 * Thiết kế lại (T7-P BJ-12): Owner tự khởi tạo trên web trong một mạch (lập → ghi nhận một lần), nhân viên lập → Owner duyệt.
 * Khuôn dùng chung K1–K4, K7 → app/shared-patterns.js. Helper ac310* / cfMoney / cfField / … → app/shared-control.js.
 * Màn đăng ký qua renderers; nguồn "Chờ duyệt" của Hub đăng ký cuối file.
 */

let cf12FileName = "ton-kho-dau-ky-2026.xlsx";
let cf12Cutoff = "2026-08-31";
let cf12ControlQty = "4820";
let cf12ControlValue = "386240000";
let cf12RejectOpen = false;
let cf12RejectReason = "";
let cf12RejectBy = "";
let cf12ColumnsOpen = false;
let cf12Filter = "all";
const cf12Maker = "Nguyễn An";
const cf12SentAt = "07/09/2026 · 10:32";
const cf12Ref = "OB-2026-0001";
const cf12Summary = { rows: 82, products: 36, parsedQty: 4820, parsedValue: 386240000, sellableRows: 74, nonSellableRows: 8 };

// 9 dòng mẫu của tệp 82 dòng (số tồn khớp BJ-01; Enrofloxacin đã hết ở BJ-01 nên không có dòng mẫu); 4 sản phẩm trùng bj01Products (tên / mã / ĐVT / lô) để hành trình chặng 1 liền mạch.
const cf12Lines = [
  { row: 2, sku: "SP-000184", name: "Nobivac DHPPi", uom: "hộp", state: "Bán được", lot: "DH2507", expiry: "30/11/2026", qty: 70, unitCost: 118000 },
  { row: 3, sku: "SP-000184", name: "Nobivac DHPPi", uom: "hộp", state: "Bán được", lot: "DH2509", expiry: "30/09/2026", qty: 48, unitCost: 118000 },
  { row: 4, sku: "SP-000184", name: "Nobivac DHPPi", uom: "hộp", state: "Cách ly", lot: "DH2509", expiry: "30/09/2026", qty: 2, unitCost: 118000 },
  { row: 5, sku: "SP-000066", name: "Amox 500", uom: "hộp", state: "Bán được", lot: "", expiry: "", qty: 47, unitCost: 86000 },
  { row: 6, sku: "SP-000066", name: "Amox 500", uom: "hộp", state: "Cách ly", lot: "", expiry: "", qty: 1, unitCost: 86000 },
  { row: 8, sku: "SP-000122", name: "Tylosin 20%", uom: "lọ", state: "Bán được", lot: "TY2511", expiry: "11/2027", qty: 7, unitCost: 72000 },
  { row: 9, sku: "SP-000122", name: "Tylosin 20%", uom: "lọ", state: "Cách ly", lot: "TY2408", expiry: "31/07/2026", qty: 11, unitCost: 72000 },
  { row: 10, sku: "SP-000147", name: "Oxytetracycline LA", uom: "chai", state: "Bán được", lot: "", expiry: "", qty: 30, unitCost: 95000 },
  { row: 11, sku: "SP-000147", name: "Oxytetracycline LA", uom: "chai", state: "Cách ly", lot: "", expiry: "", qty: 1, unitCost: 95000 },
];
const cf12Tones = { "Bán được": "Success", "Cách ly": "Warning", "Hư hỏng": "Danger" };
// "Lỗi" và "Cách sửa" tách riêng để bảng web có cột Cách sửa; mobile ghép trong cùng thẻ.
const cf12Issues = [
  { row: 18, product: "Vaccine Newcastle", error: "Chưa có sản phẩm này trong danh mục", fix: "Thêm sản phẩm ở Sản phẩm rồi kiểm tra lại" },
  { row: 44, product: "Amox 500", error: "Trùng sản phẩm + kho + tình trạng + lô với dòng 12", fix: "Gộp hai dòng trong tệp" },
  { row: 61, product: "Nobivac DHPPi", error: "Thiếu hạn dùng", fix: "Điền hạn dùng cho lô" },
];
const cf12Columns = [
  ["Mã sản phẩm", "Mã trong danh mục sản phẩm, ví dụ SP-000184."],
  ["ĐVT", "Đơn vị tồn kho của sản phẩm: hộp, chai, lọ…"],
  ["Tình trạng", "Bán được, Cách ly hoặc Hư hỏng."],
  ["Mã lô", "Bắt buộc với sản phẩm quản lý theo lô."],
  ["Hạn dùng", "Bắt buộc với sản phẩm quản lý theo hạn dùng, dạng dd/mm/yyyy."],
  ["Số lượng", "Số đang có thực tế, không nhập số âm."],
  ["Đơn giá", "Giá vốn một đơn vị, tính bằng đồng."],
];

const cf12CutoffValid = () => /^\d{4}-\d{2}-\d{2}$/.test(cf12Cutoff);
const cf12Exit = () => k1ExitAttr("SCR-066");

function cf12ReviewCard(){
  return `${crFactCard("Phạm vi khởi tạo",[["Kho","Kho trung tâm",true],["Ngày chốt số dư",cfDateVN(cf12Cutoff)],["Sản phẩm",`${cfNumber(cf12Summary.products)} sản phẩm`],["Dòng dữ liệu",`${cfNumber(cf12Summary.rows)} dòng`]])}${crFactCard("Số kiểm soát",[["Tổng số lượng",cfNumber(cf12ControlQty),true],["Tổng giá trị",cfMoney(cf12ControlValue),true],["Đối chiếu tệp","Khớp số kiểm soát"]])}`;
}
// Màn chỉ có banner + vài thẻ: giữ cột hẹp giữa khung web thay vì kéo giãn 1120px.
function cf12Narrow(html,size=""){return `<div class="cf12-narrow${size?` cf12-narrow--${size}`:""}">${html}</div>`;}
function cf12Out(html){return ac310SanitizeMarkup(html);}
function cf12Shell(opts){return appShell({...opts,extraClass:"k7-wide"});}

function bj12FileDrop(title,fileName,attrs=""){
  return `<section class="ac310-file-drop cf12-file-drop" data-ds-component="VFileDropZone"><div class="ac310-file-drop__icon">${icon("fileText")}</div><div class="ac310-file-drop__copy"><strong>${esc(title)}</strong><small class="k7-web-only">Kéo tệp vào đây hoặc Chọn tệp</small><small>${esc(fileName||"Chưa chọn tệp")}</small></div><button type="button" class="button button--secondary" ${attrs} data-ds-component="VButton">Chọn tệp</button></section>`;
}
function bj12ApprovalHash(){return [cf12FileName,cf12Cutoff,cf12ControlQty,cf12ControlValue,cf12Summary.rows,cf12Summary.parsedQty,cf12Summary.parsedValue].join("|");}
function bj12Hash(){return bj12ApprovalHash();}
function bj12ControlMatches(){return Number(cf12ControlQty)===Number(cf12Summary.parsedQty)&&Number(cf12ControlValue)===Number(cf12Summary.parsedValue);}
let bj12Cf12ApprovalHash=null;
function bj12ExitList(){return primaryFooter("Về danh sách",'data-k1-action="exit" data-k1-target="SCR-066"');}
// Mở thẳng trạng thái lệch số kiểm soát: fixture phải có chênh lệch thật (4.830 so với 4.820), không phải 0.
function cf12EnsureMismatchFixture(){if(bj12ControlMatches())cf12ControlQty=String(cf12Summary.parsedQty+10);}
function cf12Signed(n){return `${n>0?"+":n<0?"−":""}${cfNumber(Math.abs(n))}`;}

/* ---------- Thành phần dùng ở nhiều màn ---------- */

function cf12Strip(items){
  return `<div class="cf12-strip" data-composed-from="DS v2 / Metric Card">${items.map(([n,label],i)=>`${i?'<span class="cf12-strip__dot" aria-hidden="true">·</span>':""}<span class="cf12-strip__item"><strong>${esc(n)}</strong> ${esc(label)}</span>`).join("")}</div>`;
}
function cf12SummaryRows(){
  return [["Kho","Kho trung tâm"],["Ngày chốt",cfDateVN(cf12Cutoff),true],["Sản phẩm",`${cfNumber(cf12Summary.products)} sản phẩm`],["Dòng dữ liệu",`${cfNumber(cf12Summary.rows)} dòng`],["Tổng số lượng",cfNumber(cf12Summary.parsedQty)],["Tổng giá trị",cfMoney(cf12Summary.parsedValue),true]];
}
function cf12LineBadge(state){return ds24Badge(state,cf12Tones[state]||"Neutral");}
function cf12LineMobileRow(r){
  const sub=[r.sku,r.lot?`Lô ${r.lot}`:"Không theo lô",r.expiry?`HSD ${r.expiry}`:""].filter(Boolean).join(" · ");
  return ac310RecordRow({title:`${r.name} · ${cfNumber(r.qty)} ${r.uom}`,subtitle:sub,badge:r.state,tone:cf12Tones[r.state]||"Neutral",status:true,leading:null});
}
// Bảng dòng sẽ vào kho (068 đạt + 070): lọc Tất cả / Bán được / Không bán được; số trên chip là của cả tệp, bảng chỉ hiện dòng mẫu.
function cf12LinesBlock(){
  const sellable=(r)=>r.state==="Bán được";
  const shown=cf12Lines.filter((r)=>cf12Filter==="all"||(cf12Filter==="sellable"?sellable(r):!sellable(r)));
  const total=cf12Filter==="all"?cf12Summary.rows:cf12Filter==="sellable"?cf12Summary.sellableRows:cf12Summary.nonSellableRows;
  const rows=shown.map((r)=>({...r,product:`<strong>${esc(r.name)}</strong><small>${esc(r.sku)}</small>`,stateHtml:cf12LineBadge(r.state),lotHtml:r.lot?`${esc(r.lot)}<small>${esc(r.expiry)}</small>`:'<span class="k7-muted">—</span>',qtyText:`${cfNumber(r.qty)} ${r.uom}`,costText:cfMoney(r.unitCost)}));
  const columns=[{key:"row",label:"Dòng",mono:true},{key:"product",label:"Sản phẩm",html:true},{key:"stateHtml",label:"Tình trạng",html:true},{key:"lotHtml",label:"Lô / hạn dùng",html:true},{key:"qtyText",label:"Số lượng",align:"end",mono:true},{key:"costText",label:"Đơn giá",align:"end",mono:true}];
  const chips=k7FilterChips({items:[["all","Tất cả",cf12Summary.rows],["sellable","Bán được",cf12Summary.sellableRows],["nonSellable","Không bán được",cf12Summary.nonSellableRows]],selected:cf12Filter,attrName:"data-cf12-filter"});
  const table=k7Table({columns,rows,mobileRow:cf12LineMobileRow,caption:"Dòng số dư đầu kỳ",footer:`Hiện ${shown.length} / ${cfNumber(total)} dòng`,empty:{title:"Không có dòng nào",description:"Bộ lọc hiện tại không có dòng. Chọn bộ lọc khác để xem thêm.",actionLabel:"Xem tất cả",actionAttr:'data-cf12-filter="all"'}});
  return `${ac310SectionTitle("Dòng sẽ vào kho")}${chips}${table}`;
}
function cf12ColumnsList(){
  return `<dl class="cf12-columns">${cf12Columns.map(([name,desc])=>`<div class="cf12-columns__row"><dt>${esc(name)}</dt><dd>${esc(desc)}</dd></div>`).join("")}</dl>`;
}
function cf12ColumnsAside(){
  return `<section class="ac310-surface cf12-columns-surface" data-layout-pattern="Grouped surface"><div class="ac310-surface__head"><h2>Tệp cần có các cột</h2></div>${cf12ColumnsList()}</section>`;
}
function cf12ColumnsSheet(){
  if(!cf12ColumnsOpen)return "";
  const close='data-cf12-action="close-columns"';
  return `<div class="sheet-backdrop k7-mobile-only" ${close}><section class="bottom-sheet cf12-columns-sheet" role="dialog" aria-modal="true" aria-label="Tệp cần có các cột" onclick="event.stopPropagation()" data-ds-component="VBottomSheet" data-figma-node="4695:6353"><div class="sheet-handle"></div><div class="sheet-title"><h3>Tệp cần có các cột</h3></div><div class="sheet-divider"></div><div class="sheet-content">${cf12ColumnsList()}<div class="sheet-actions">${cfSecondary("Đóng",close)}</div></div></section></div>`;
}
function cf12RejectSheet(){
  return k2RejectSheet({open:cf12RejectOpen,title:"Từ chối số dư đầu kỳ",reason:cf12RejectReason,reasonAttr:"data-cf12-reject-reason",confirmAttr:'data-bj12-action="cf12-confirm-reject"',closeAttr:'data-cf12-action="close-reject"'});
}

/* ---------- SCR-066 Khởi tạo tồn kho ---------- */

function render066BJ12(state){
  const title="Khởi tạo tồn kho";
  const baseFacts=[["Kho","Kho trung tâm"],["Ngày chốt",cfDateVN(cf12Cutoff)],["Sản phẩm",`${cfNumber(cf12Summary.products)} sản phẩm`]];
  if(state==="READY"){
    const prepare=`<section class="ac310-surface cf12-prepare" data-layout-pattern="Grouped surface"><div class="ac310-surface__head"><h2>Cần chuẩn bị</h2></div><ul class="cf12-prepare__list"><li>${icon("fileText","icon--sm")}<span><strong>Tệp số dư theo mẫu</strong></span><button class="button button--secondary cf12-prepare__action" type="button" data-cf12-action="template" data-ds-component="VButton" data-ds-prop-variant="VButtonVariant.secondary" data-ds-prop-size="VButtonSize.medium">Tải tệp mẫu</button></li><li>${icon("calendar","icon--sm")}<span><strong>Ngày chốt số dư</strong></span></li><li>${icon("listCheck","icon--sm")}<span><strong>Tổng số lượng và tổng giá trị theo sổ để đối chiếu</strong></span></li></ul></section>`;
    return cf12Out(cf12Shell({title,body:cf12Narrow(`<p class="cf12-lead">Nhập số tồn hiện có của cửa hàng một lần để bắt đầu dùng Kho.</p>${prepare}<p class="ac310-note">Sau khi hoàn tất, mọi sửa sai được thực hiện bằng nghiệp vụ điều chỉnh có kiểm soát.</p>`),actions:primaryFooter("Bắt đầu",'data-cf12-action="start"'),back:false}));
  }
  if(state==="PREPARING") return cf12Out(cf12Shell({title,body:cf12Narrow(`${vBanner("info","Đang chuẩn bị số dư đầu kỳ","Tệp và số kiểm soát đã được giữ lại. Tiếp tục rà soát dữ liệu trước khi gửi phê duyệt.")}${cf12ReviewCard()}`),actions:primaryFooter("Tiếp tục chuẩn bị",'data-cf12-action="continue-prepare"'),back:false}));
  if(state==="PENDING_APPROVAL") return cf12Out(cf12Shell({title,body:cf12Narrow(k2Pending({approver:"Chủ cửa hàng",sentAt:cf12SentAt,facts:baseFacts})),actions:primaryFooter("Về Kho",cf12Exit()),back:false}));
  if(state==="REJECTED"){
    const by=cf12RejectBy||"Chủ cửa hàng", reason=cf12RejectReason||"Cần kiểm tra lại số liệu trước khi gửi lại.";
    return cf12Out(cf12Shell({title,body:cf12Narrow(`${vBanner("warning","Yêu cầu cần chỉnh sửa","Người duyệt đã trả lại dữ liệu. Tồn kho chưa thay đổi.")}${ac310InfoSurface("Yêu cầu",[...baseFacts.slice(0,2),["Người từ chối",by],["Lý do",reason]])}`),actions:primaryFooter("Tiếp tục chuẩn bị",'data-cf12-action="fix-rejected"'),back:false}));
  }
  if(state==="ACTIVE_RECONCILED") return cf12Out(k4Result({screenTitle:title,title:"Tồn kho đầu kỳ đã sẵn sàng",description:"Số dư đầu kỳ đã được ghi nhận và đối chiếu.",facts:[["Ngày chốt",cfDateVN(cf12Cutoff)],["Sản phẩm",`${cfNumber(cf12Summary.products)} sản phẩm`],["Đối soát","Đã khớp"]],next:[{label:"Đặt ngưỡng tồn",attr:'data-cf12-action="go-policy"'},{label:"Xem tồn kho",attr:'data-cf12-action="see-inventory"',primary:true}]}));
  if(state==="UNKNOWN") return k3Unknown({operation:"Khởi tạo tồn kho đầu kỳ",scope:`Kho trung tâm · ${cfDateVN(cf12Cutoff)}`,ref:cf12Ref,sentAt:cf12SentAt,safe:"Không nạp lại tệp hay gửi lại.",sourceFlow:"UIF-12",exitAttr:cf12Exit(),facts:[["Tồn kho","Chưa mở cho đến khi xác minh xong"]]});
  if(state==="PERMISSION_DENIED") return cf12Out(cf12Shell({title,body:k1Denied({what:"khởi tạo tồn kho",next:"Chỉ chủ cửa hàng hoặc người được giao mới khởi tạo được tồn đầu kỳ. Nhờ họ cấp quyền rồi quay lại.",exitAttr:cf12Exit()}),centered:true,back:false}));
  return cf12Out(cf12Shell({title,body:cf12Narrow(k1Loading({blocks:["heading","card","row","row"]})),back:false}));
}

/* ---------- SCR-067 Dữ liệu tồn kho đầu kỳ ---------- */

function render067BJ12(state){
  const title="Dữ liệu tồn kho đầu kỳ";
  if(["READY","VALIDATION_ERROR"].includes(state)){
    const invalid=state==="VALIDATION_ERROR";
    const err={file:invalid&&!cf12FileName?"Chọn tệp số dư":"",cutoff:invalid&&!cf12CutoffValid()?"Chọn ngày chốt số dư":"",qty:invalid&&cf12ControlQty===""?"Nhập tổng số lượng theo sổ":"",value:invalid&&cf12ControlValue===""?"Nhập tổng giá trị theo sổ":""};
    // Mở thẳng trạng thái lỗi khi dữ liệu đã đủ: ô giá trị trống để thấy lỗi tại ô (như ví dụ của brief).
    const demoEmpty=invalid&&!err.file&&!err.cutoff&&!err.qty&&!err.value;
    if(demoEmpty) err.value="Nhập tổng giá trị theo sổ";
    const valueShown=demoEmpty?"":cf12ControlValue;
    const banner=invalid?vBanner("error","Chưa đủ dữ liệu kiểm soát","Điền các ô được đánh dấu trước khi kiểm tra."):"";
    const fileError=err.file?`<small class="field-error" role="alert">${err.file}</small>`:"";
    const main=`${banner}${bj12FileDrop("Tệp số dư đầu kỳ",cf12FileName,'data-cf12-action="choose-file"')}${fileError}<button class="button button--secondary cf12-template" type="button" data-cf12-action="template" data-ds-component="VButton" data-ds-prop-variant="VButtonVariant.secondary" data-ds-prop-size="VButtonSize.medium">Tải tệp mẫu</button><button class="button button--secondary k7-mobile-only" type="button" data-cf12-action="open-columns" data-ds-component="VButton" data-ds-prop-variant="VButtonVariant.secondary" data-ds-prop-size="VButtonSize.medium">Xem các cột cần có</button><div class="ac310-form-stack">${cfField("Ngày chốt số dư",cf12Cutoff,'data-cf12-cutoff aria-label="Ngày chốt số dư"',"date","Ngày nghiệp vụ mà số dư đầu kỳ có hiệu lực.",err.cutoff)}${cfField("Tổng số lượng kiểm soát",cf12ControlQty,'data-cf12-control-qty aria-label="Tổng số lượng kiểm soát"',"number","Nhập từ nguồn kiểm soát độc lập.",err.qty)}${cfField("Tổng giá trị kiểm soát",valueShown,'data-cf12-control-value aria-label="Tổng giá trị kiểm soát"',"money","Giá trị tồn kho đầu kỳ theo nguồn kiểm soát.",err.value)}</div>`;
    const body=`${k7Split({main,aside:`<div class="k7-web-only">${cf12ColumnsAside()}</div>`})}${cf12ColumnsSheet()}`;
    return cf12Out(cf12Shell({title,body,actions:primaryFooter("Kiểm tra dữ liệu",'data-bj12-action="cf12-check"',!cf12FileName)}));
  }
  if(state==="PERMISSION_DENIED") return cf12Out(cf12Shell({title,body:k1Denied({what:"khởi tạo tồn kho",next:"Chỉ chủ cửa hàng hoặc người được giao mới nhập được dữ liệu tồn đầu kỳ. Nhờ họ cấp quyền rồi quay lại.",exitAttr:cf12Exit()}),centered:true}));
  if(state==="LOCKED") return cf12Out(cf12Shell({title,body:cf12Narrow(`${k1Locked({title:"Dữ liệu đang được xử lý",description:"Tệp nguồn và số kiểm soát hiện chỉ đọc cho đến khi xử lý xong."})}${cf12ReviewCard()}`)}));
  if(state==="CONFLICT") return cf12Out(cf12Shell({title,body:cf12Narrow(`${k1Stale({title:"Phạm vi vừa thay đổi",description:"Không tiếp tục trên dữ liệu cũ. Tải lại thông tin hiện hành trước khi kiểm tra tệp.",actionAttr:'data-cf12-action="reload"'})}${cf12ReviewCard()}`)}));
  return cf12Out(cf12Shell({title,body:cf12Narrow(k1Denied({what:"xem màn này",next:"Quay lại Kho và thử lại.",exitAttr:cf12Exit()})),centered:true}));
}

/* ---------- SCR-068 Kết quả kiểm tra dữ liệu (gồm phần rà soát của SCR-069 cũ) ---------- */

function render068BJ12(state){
  const title="Kết quả kiểm tra dữ liệu";
  if(state==="CONTROL_TOTAL_MISMATCH"){
    cf12EnsureMismatchFixture();
    const dq=Number(cf12ControlQty)-Number(cf12Summary.parsedQty),dv=Number(cf12ControlValue)-Number(cf12Summary.parsedValue);
    const rows=[{label:"Tổng số lượng",file:cfNumber(cf12Summary.parsedQty),ledger:cfNumber(cf12ControlQty),diff:cf12Signed(dq),off:dq!==0},{label:"Tổng giá trị",file:cfMoney(cf12Summary.parsedValue),ledger:cfMoney(cf12ControlValue),diff:`${dv>0?"+":dv<0?"−":""}${cfMoney(Math.abs(dv))}`,off:dv!==0}];
    const warn=(r)=>r.off?"k7-cell--warn":"";
    const table=k7Table({columns:[{key:"label",label:"Chỉ tiêu"},{key:"file",label:"Theo tệp",align:"end",mono:true},{key:"ledger",label:"Theo sổ",align:"end",mono:true},{key:"diff",label:"Chênh lệch",align:"end",mono:true,cls:warn}],rows,mobileRow:(r)=>crFactCard(r.label,[["Theo tệp",r.file,true],["Theo sổ",r.ledger,true],["Chênh lệch",r.diff,r.off]]),caption:"Đối chiếu số kiểm soát"});
    const footer=k4Footer([{label:"Chọn lại tệp",attr:'data-cf12-action="back-file"'},{label:"Sửa số kiểm soát",attr:'data-cf12-action="back-control"',primary:true}]);
    return cf12Out(cf12Shell({title,body:cf12Narrow(`${vBanner("warning","Số kiểm soát không khớp","Không gửi phê duyệt cho đến khi tệp chi tiết khớp nguồn kiểm soát độc lập.")}${table}`,"mid"),actions:footer}));
  }
  if(state==="VALIDATION_FAILED"){
    const table=k7Table({columns:[{key:"row",label:"Dòng",mono:true},{key:"product",label:"Sản phẩm"},{key:"error",label:"Lỗi"},{key:"fix",label:"Cách sửa"}],rows:cf12Issues,mobileRow:cf12IssueCard,caption:"Dòng cần sửa"});
    const strip=cf12Strip([[cfNumber(cf12Summary.rows),"dòng đọc được"],[cfNumber(cf12Summary.rows-cf12Issues.length),"hợp lệ"],[String(cf12Issues.length),"cần sửa"]]);
    return cf12Out(cf12Shell({title,body:cf12Narrow(`${vBanner("error","Còn dòng chưa hợp lệ","Không có dữ liệu nào được ghi nhận. Sửa dữ liệu nguồn rồi kiểm tra lại.")}${strip}${ac310SectionTitle("Dòng cần sửa")}${table}`,"mid"),actions:primaryFooter("Chọn lại tệp",'data-cf12-action="back-file"')}));
  }
  if(state==="READY"){
    const summary=`<section class="ac310-surface cf12-ready-summary" data-layout-pattern="Grouped surface"><div class="ac310-surface__head"><h2>Số dư sẽ ghi nhận</h2></div><div class="ac310-info-rows">${cf12SummaryRows().map((r)=>ds24InfoRow(r[0],r[1],r[2]?"ac310-info-row--emphasis":"")).join("")}</div><div class="cf12-match">${icon("checkCircle","icon--sm")}<strong>Khớp số kiểm soát</strong></div></section>`;
    const actions=primaryFooter("Gửi phê duyệt",'data-bj12-action="cf12-send-approval"');
    return cf12Out(cf12Shell({title,body:`${vBanner("success","Dữ liệu đã qua kiểm tra","","k7-banner--line")}${k7Split({main:summary,aside:cf12LinesBlock()})}`,actions}));
  }
  if(state==="PERMISSION_DENIED") return cf12Out(cf12Shell({title,body:k1Denied({what:"xem kết quả kiểm tra",next:"Chỉ chủ cửa hàng hoặc người được giao mới xem được kết quả kiểm tra tồn đầu kỳ. Nhờ họ cấp quyền rồi quay lại.",exitAttr:cf12Exit()}),centered:true}));
  if(state==="CONFLICT") return cf12Out(cf12Shell({title,body:cf12Narrow(`${k1Stale({title:"Nguồn dữ liệu đã thay đổi",description:"Kết quả kiểm tra cũ không còn hiệu lực. Chọn lại tệp hoặc tải lại phạm vi.",actionAttr:'data-cf12-action="reload"'})}${cf12ReviewCard()}`),actions:primaryFooter("Quay lại dữ liệu",'data-cf12-action="back-file"')}));
  return cf12Out(cf12Shell({title,body:cf12Narrow(k1Loading({blocks:["heading","card","row","row"]}),"mid")}));
}
// Thẻ lỗi trên iPhone: dòng "Cách sửa" nằm ngay dưới lỗi (ds24ListRow cắt một dòng nên không dùng cho chữ dài).
function cf12IssueCard(r){
  return `<article class="cf12-issue" data-ds-component="DS v2 / List Row" data-ds-prop-type="Status"><div class="cf12-issue__head"><strong>Dòng ${esc(r.row)} · ${esc(r.product)}</strong>${ds24Badge("Cần sửa","Warning")}</div><p class="cf12-issue__error">${esc(r.error)}</p><p class="cf12-issue__fix"><span>Cách sửa</span> ${esc(r.fix)}</p></article>`;
}

/* ---------- SCR-070 Duyệt số dư đầu kỳ ---------- */

function render070BJ12(state){
  const title="Duyệt số dư đầu kỳ";
  if(state==="READY"){
    const facts=[["Ngày chốt",cfDateVN(cf12Cutoff),true],["Sản phẩm",`${cfNumber(cf12Summary.products)} sản phẩm`],["Dòng dữ liệu",`${cfNumber(cf12Summary.rows)} dòng`],["Tổng số lượng",cfNumber(cf12Summary.parsedQty)],["Tổng giá trị",cfMoney(cf12Summary.parsedValue),true],["Đối chiếu số kiểm soát","Khớp số kiểm soát ✓"]];
    const decision=k2Decision({question:`Duyệt số dư đầu kỳ của Kho trung tâm, chốt ${cfDateVN(cf12Cutoff)}?`,maker:cf12Maker,sentAt:cf12SentAt,attention:[["Không bán được",`${cfNumber(cf12Summary.nonSellableRows)} dòng (cách ly / hư hỏng)`],["Sau khi duyệt","Kho bắt đầu hoạt động","info"]],facts});
    return cf12Out(cf12Shell({title,body:`${k7Split({main:decision,aside:cf12LinesBlock()})}${cf12RejectSheet()}`,actions:ac310ApprovalFooter('data-cf12-action="open-reject"','data-bj12-action="cf12-approve"'),back:false}));
  }
  if(state==="PERMISSION_DENIED") return cf12Out(cf12Shell({title,body:k1Denied({what:"duyệt số dư đầu kỳ",next:"Chỉ chủ cửa hàng hoặc người được giao quyền duyệt mới quyết định được. Nhờ họ cấp quyền rồi quay lại.",exitAttr:cf12Exit()}),centered:true,back:false}));
  if(state==="SELF_APPROVAL_NOT_ALLOWED") return cf12Out(cf12Shell({title,body:cf12Narrow(`${vBanner("warning","Không thể tự duyệt","Người chuẩn bị số dư đầu kỳ không được đồng thời là người quyết định.")}${cf12ReviewCard()}`),actions:bj12ExitList(),back:false}));
  if(state==="APPROVAL_ALREADY_DECIDED") return cf12Out(cf12Shell({title,body:cf12Narrow(`${vBanner("info","Công việc đã có quyết định","Quyết định hợp lệ đầu tiên có hiệu lực. Màn này chỉ còn để xem bằng chứng đã dùng.")}${cf12ReviewCard()}`),actions:bj12ExitList(),back:false}));
  if(state==="VALIDATION_ERROR") return cf12Out(cf12Shell({title,body:cf12Narrow(`${vBanner("error","Không thể quyết định","Dữ liệu nền không còn hợp lệ. Không ghi nhận số dư từ bằng chứng đã thay đổi.")}${cf12ReviewCard()}`),actions:bj12ExitList(),back:false}));
  return cf12Out(cf12Shell({title,body:k1Denied({what:"xem màn này",next:"Quay lại Kho và thử lại.",exitAttr:cf12Exit()}),centered:true,back:false}));
}

/* ---------- SCR-071 Kết quả khởi tạo tồn kho ---------- */

function render071BJ12(state){
  const title="Kết quả khởi tạo tồn kho";
  if(state==="UNKNOWN"||state==="COMMIT_UNKNOWN") return k3Unknown({operation:"Khởi tạo tồn kho đầu kỳ",scope:`Kho trung tâm · ${cfDateVN(cf12Cutoff)}`,ref:cf12Ref,sentAt:cf12SentAt,safe:"Không nạp lại tệp hay gửi lại.",sourceFlow:"UIF-12",exitAttr:cf12Exit(),facts:[["Tồn kho","Chưa mở cho đến khi xác minh xong"]]});
  if(state==="PERMISSION_DENIED") return cf12Out(cf12Shell({title,body:k1Denied({what:"xem kết quả này",next:"Chỉ chủ cửa hàng hoặc người được giao mới xem được kết quả khởi tạo tồn kho. Nhờ họ cấp quyền rồi quay lại.",exitAttr:cf12Exit()}),centered:true,back:false}));
  if(state==="PROCESSING") return cf12Out(cf12Shell({title,body:cf12Narrow(`${loadingBody()}${vBanner("info","Đang ghi nhận và đối soát","Hệ thống đang xử lý số dư được duyệt. Không cần thực hiện thêm thao tác.")}`),centered:true,back:false}));
  if(state==="REJECTED_EXECUTION") return cf12Out(k4Result({screenTitle:title,kind:"warning",title:"Chưa khởi tạo tồn kho",description:"Yêu cầu không được thực hiện. Không có số dư đầu kỳ nào được ghi nhận.",facts:[["Ngày chốt số dư",cfDateVN(cf12Cutoff)],["Tác động tồn kho","Không có"],["Lý do","Dữ liệu nguồn đã thay đổi trước khi ghi nhận"]],next:[{label:"Tiếp tục chuẩn bị",attr:'data-cf12-action="continue-prepare"',primary:true}]}));
  return cf12Out(k4Result({screenTitle:title,title:"Đã khởi tạo tồn kho đầu kỳ",description:"Số dư đã được ghi nhận nguyên khối và đối soát thành công. Mọi sửa sai tiếp theo đi qua nghiệp vụ điều chỉnh có kiểm soát.",facts:[["Ngày chốt số dư",cfDateVN(cf12Cutoff)],["Sản phẩm",`${cfNumber(cf12Summary.products)} sản phẩm`],["Tổng số lượng",cfNumber(cf12Summary.parsedQty)],["Tổng giá trị",cfMoney(cf12Summary.parsedValue)],["Đối soát","Đã khớp"],["Người duyệt","Chủ cửa hàng"]],next:[{label:"Đặt ngưỡng tồn",attr:'data-cf12-action="go-policy"'},{label:"Xem tồn kho",attr:'data-cf12-action="see-inventory"',primary:true}]}));
}

/* ---------- Xử lý sự kiện ---------- */

// Ghi nhận do hệ thống sau khi người duyệt (chủ cửa hàng, kể cả khi chính họ lập) bấm "Duyệt": PROCESSING rồi COMPLETED.
function cf12Commit(){
  stateByScreen["SCR-071"]="PROCESSING";navigate("SCR-071");
  setTimeout(()=>{
    if(activeFlowId==="UIF-12"&&activeScreenId==="SCR-071"&&stateByScreen["SCR-071"]==="PROCESSING"){
      stateByScreen["SCR-071"]="COMPLETED";stateByScreen["SCR-066"]="ACTIVE_RECONCILED";
      if(typeof ThemeApp!=="undefined")ThemeApp.setActivated(true);
      syncReviewUrl();render();
    }
  },420);
}
function cf12CloseSheets(){const open=cf12RejectOpen||cf12ColumnsOpen;cf12RejectOpen=false;cf12ColumnsOpen=false;return open;}

document.addEventListener("input",(event)=>{
  if(activeFlowId!=="UIF-12") return;
  const t=event.target;
  // Sửa ô đang báo lỗi: bỏ lỗi tại ô ngay khi ô có giá trị.
  const clearError=()=>{const f=t.closest(".cf-field");if(f&&t.value!==""){f.classList.remove("cf-field--error");f.querySelector(".field-error")?.remove();t.removeAttribute("aria-invalid");}};
  if(t.matches("[data-cf12-cutoff]")){cf12Cutoff=cfDateKey(t.value);clearError();return;}
  if(t.matches("[data-cf12-control-qty]")){cf12ControlQty=t.value;clearError();return;}
  if(t.matches("[data-cf12-control-value]")){cf12ControlValue=String(t.value||"").replace(/[^0-9]/g,"");t.value=cfMoneyInput(cf12ControlValue);clearError();return;}
  if(t.matches("[data-cf12-reject-reason]")){
    cf12RejectReason=t.value;
    const b=document.querySelector('[data-bj12-action="cf12-confirm-reject"]'); if(b)b.disabled=!cf12RejectReason.trim();
    return;
  }
},true);
onDialogClose["UIF-12"]=()=>{
  if(!cf12CloseSheets()) return false;
  renderAppScreen(); return true;
};
document.addEventListener("click",(event)=>{
  if(activeFlowId!=="UIF-12") return;
  // data-bj12-action trước — nút confirm-reject nằm trong backdrop close-reject
  const v=event.target.closest("[data-bj12-action]");
  if(v&&!v.disabled){
    const k=v.dataset.bj12Action;
    if(["cf12-check","cf12-send-approval","cf12-approve","cf12-confirm-reject"].includes(k)){
      event.preventDefault();event.stopPropagation();
      if(k==="cf12-check"){
        const valid=Boolean(cf12FileName&&cf12CutoffValid()&&cf12ControlQty!==""&&cf12ControlValue!==""&&Number(cf12ControlQty)>=0&&Number(cf12ControlValue)>=0);
        if(!valid){stateByScreen["SCR-067"]="VALIDATION_ERROR";syncReviewUrl();return renderAppScreen();}
        cf12Filter="all";
        stateByScreen["SCR-068"]=bj12ControlMatches()?"READY":"CONTROL_TOTAL_MISMATCH";return navigate("SCR-068");
      }
      if(k==="cf12-send-approval"){if(!bj12ControlMatches()){stateByScreen["SCR-068"]="CONTROL_TOTAL_MISMATCH";return navigate("SCR-068");}bj12Cf12ApprovalHash=bj12Hash();stateByScreen["SCR-066"]="PENDING_APPROVAL";return navigate("SCR-066");}
      if(k==="cf12-approve"){
        if(!["approver","owner"].includes(currentActor())){stateByScreen["SCR-070"]="SELF_APPROVAL_NOT_ALLOWED";syncReviewUrl();return renderAppScreen();}
        if(!bj12Cf12ApprovalHash||bj12Cf12ApprovalHash!==bj12Hash()){stateByScreen["SCR-070"]="VALIDATION_ERROR";syncReviewUrl();return renderAppScreen();}
        return cf12Commit();
      }
      if(k==="cf12-confirm-reject"){
        if(!["approver","owner"].includes(currentActor())){stateByScreen["SCR-070"]="SELF_APPROVAL_NOT_ALLOWED";syncReviewUrl();return renderAppScreen();}
        if(!cf12RejectReason.trim())return;cf12RejectOpen=false;cf12RejectBy="Chủ cửa hàng";stateByScreen["SCR-070"]="APPROVAL_ALREADY_DECIDED";stateByScreen["SCR-066"]="REJECTED";syncReviewUrl();return renderAppScreen();
      }
    }
  }
  const f=event.target.closest("[data-cf12-filter]");
  if(f){event.preventDefault();event.stopPropagation();cf12Filter=f.dataset.cf12Filter;return renderAppScreen();}
  const a=event.target.closest("[data-cf12-action]");
  if(a&&!a.disabled){
    event.preventDefault(); event.stopPropagation(); const k=a.dataset.cf12Action;
    if(k==="start"||k==="continue-prepare"){stateByScreen["SCR-067"]="READY";return navigate("SCR-067");}
    if(k==="choose-file"){cf12FileName="ton-kho-dau-ky-2026.xlsx";stateByScreen["SCR-067"]="READY";return renderAppScreen();}
    if(k==="template"){return showToast("Đã tải tệp mẫu");}
    if(k==="open-columns"){cf12ColumnsOpen=true;return renderAppScreen();}
    if(k==="close-columns"){cf12ColumnsOpen=false;return renderAppScreen();}
    if(k==="back-file"){stateByScreen["SCR-067"]="READY";return navigate("SCR-067");}
    // "Sửa số kiểm soát": về 067 và đặt con trỏ vào ô "Tổng số lượng kiểm soát" (số cần sửa), không phải đầu trang.
    if(k==="back-control"){stateByScreen["SCR-067"]="READY";navigate("SCR-067");return requestAnimationFrame(()=>document.querySelector("[data-cf12-control-qty]")?.focus());}
    if(k==="reload"){if(activeScreenId==="SCR-067"){stateByScreen["SCR-067"]="READY";return renderAppScreen();}stateByScreen["SCR-067"]="READY";return navigate("SCR-067");}
    if(k==="fix-rejected"){stateByScreen["SCR-067"]="READY";return navigate("SCR-067");}
    if(k==="open-reject"){cf12RejectOpen=true;cf12RejectReason="";return renderAppScreen();}
    if(k==="close-reject"){cf12RejectOpen=false;cf12RejectReason="";return renderAppScreen();}
    if(k==="result-home"){return navigate("SCR-066");}
    if(k==="see-inventory"){activeFlowId="UIF-01";activeScreenId="SCR-001";stateByScreen["SCR-001"]="READY";syncReviewUrl();return render();}
    if(k==="go-policy"){return capOpenForTable("UIF-12","SCR-071");}
  }
},true);


// SCR-069 đã gộp vào SCR-068 (khi kiểm tra đạt, 068 là màn rà soát); link cũ vẫn mở.
screenAliases["UIF-12"]=Object.assign(screenAliases["UIF-12"]||{},{"SCR-069":"SCR-068"});
{ const a=screenAliases[activeFlowId]?.[activeScreenId]; if(Array.isArray(a)){activeFlowId=a[0];activeScreenId=a[1];}else if(a)activeScreenId=a; }

Object.assign(renderers, {
  "SCR-066": render066BJ12,
  "SCR-067": render067BJ12,
  "SCR-068": render068BJ12,
  "SCR-070": render070BJ12,
  "SCR-071": render071BJ12
});

// Nguồn "Chờ duyệt" của Hub (K2): hiện khi người lập đã gửi và chưa có quyết định.
(window.__T7_PENDING_SOURCES__ ||= []).push({ id:"UIF-12", label:"số dư đầu kỳ", rows:() => stateByScreen["SCR-066"]==="PENDING_APPROVAL" ? [{ title:"Số dư đầu kỳ · Kho trung tâm", subtitle:`Chốt ${cfDateVN(cf12Cutoff)} · ${cf12Maker} gửi 10:32`, icon:"inbox", attrs:'data-theme-entry-flow="UIF-12" data-t380-target-screen="SCR-070" data-theme-entry-actor="approver"' }] : [] });

Object.assign(window.__VET45_QA__, {
  setCf12Control(qty,value){cf12ControlQty=String(qty);cf12ControlValue=String(value);return bj12ControlMatches();}
});
