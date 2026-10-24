/* BJ-04 — Quản lý vòng đời giữ hàng (UIF-04). Màn: SCR-021.
 *
 * Thiết kế lại (T7-P BJ-04 / BJ-05, 2026-10-24, v5.11.0): mọi hàm dựng, fixture và xử lý sự kiện của BJ-04 nằm ở đây.
 * Sửa BJ-04: sửa thẳng file này.
 * Chỉ xem: giữ hàng do đơn bán (Theme 5) tạo / sửa / giải phóng. Đơn có trong hàng đợi lấy hàng (BJ-05) lấy số liệu từ
 * io05Orders; đơn tĩnh SO-260827-18 giữ làm mẫu đủ ca (combo, đã bàn giao, đã giải phóng).
 * Dùng từ khuôn: k1Loading, k1Denied, k1ExitAttr (K1); k7Split, k7Table (K7); cf12Strip (BJ-12).
 * Dùng chung từ app/core.js: appShell, ds24ListRow, ds24Badge, ds24SectionTitle, ac310InfoSurface, vBanner, primaryFooter,
 * applyEntry, showToast.
 */

// ---- Fixture và trạng thái
const bj04Lines = [
  {id:'RSV-L1',name:'Nobivac DHPPi',code:'SP-000184',uom:'hộp',uomId:'UOM-BOX',uomSnapshot:{label:'hộp',step:1},conversionToBase:10,conversionVersion:'UOM-SP000184-v2',requested:20,reserved:16,consumed:4,policy:'PARTIAL_ALLOWED',priority:10,confirmedAt:'2026-08-27T01:10:00Z',lifecycle:'PARTIALLY_CONSUMED'},
  {id:'RSV-L2',name:'Amox 500',code:'SP-000066',uom:'hộp',uomId:'UOM-BOX',uomSnapshot:{label:'hộp',step:1},conversionToBase:1,conversionVersion:'UOM-SP000066-v1',requested:50,reserved:42,consumed:0,policy:'PARTIAL_ALLOWED',priority:10,confirmedAt:'2026-08-27T01:11:00Z',lifecycle:'ACTIVE'},
  {id:'RSV-G1',name:'Bộ chăm sóc cơ bản',code:'CB-0007',uom:'bộ',uomId:'UOM-COMBO',uomSnapshot:{label:'bộ',step:1},conversionToBase:null,conversionVersion:'COMBO-CB0007-v4',requested:3,reserved:2,consumed:0,policy:'PARTIAL_ALLOWED',priority:20,confirmedAt:'2026-08-27T01:12:00Z',lifecycle:'ACTIVE',reservationGroupId:'RG-CB0007-01',comboDefinitionVersion:4,components:[{product:'SP-000184',qtyPerCombo:2},{product:'SP-000099',qtyPerCombo:1}]},
  {id:'RSV-L4',name:'Vitamin ADE',code:'SP-000099',uom:'chai',uomId:'UOM-BOTTLE',uomSnapshot:{label:'chai',step:1},conversionToBase:1,conversionVersion:'UOM-SP000099-v1',requested:6,reserved:0,consumed:6,policy:'PARTIAL_ALLOWED',priority:10,confirmedAt:'2026-08-27T01:13:00Z',lifecycle:'CONSUMED'}
];
const bj04StaticModel = {order:'SO-260827-18',customer:'Cửa hàng Thú y Hòa Bình',warehouse:'Kho chính',inventoryMode:'ADVANCED',reservationPolicy:'PARTIAL_ALLOWED',sourceStatus:'Đã xác nhận',sourceConfirmedAt:'27/08/2026 08:10',lines:bj04Lines,pick:false};
let bj04OrderId = bj04StaticModel.order;
let bj04ReturnTo = null; // "UIF-05" khi mở từ "Xem giữ hàng" ở Hàng cần lấy: nút quay lại về lại đó

// Đơn có trong hàng đợi lấy hàng: dựng từ BJ-05 (đang giữ = phân bổ − đã bàn giao; thiếu = cần − đã bàn giao − đang giữ).
function bj04OrderModel(orderId = bj04OrderId) {
  const o = typeof io05Orders !== 'undefined' ? io05Orders.find((x) => x.id === orderId) : null;
  if (!o) return bj04StaticModel;
  const lines = o.lines.map((l) => {
    const consumed = io05LineDelivered(l), requested = io05LineRequested(l), reserved = Math.max(0, io05LineAllocated(l) - consumed);
    return {id:`RSV-${l.id}`,name:l.name,code:l.code,uom:l.uom,requested,reserved,consumed,policy:o.partialHandoverAllowed?'PARTIAL_ALLOWED':'ALL_OR_NOTHING',lifecycle:consumed>=requested?'CONSUMED':consumed>0?'PARTIALLY_CONSUMED':'ACTIVE'};
  });
  const q = io05Queue(o);
  return {order:o.id,customer:o.customer,warehouse:o.warehouse,sourceStatus:'Đã xác nhận',lines,pick:!o.closed&&(q==='PICK'||q==='HANDOVER')};
}

function bj04Remaining(l){return Math.max(0,Number(l.requested||0)-Number(l.consumed||0));}
function bj04Shortage(l){return Math.max(0,bj04Remaining(l)-Number(l.reserved||0));}
function bj04ActiveHold(l){return Math.max(0,Number(l.reserved||0));}
function bj04Terminal(l){return ['CONSUMED','RELEASED','EXPIRED'].includes(l.lifecycle);}
function bj04LifecycleLabel(l){return ({CONSUMED:'Đã bàn giao',RELEASED:'Đã giải phóng',EXPIRED:'Đã hết hạn giữ',PARTIALLY_CONSUMED:'Đã bàn giao một phần'}[l.lifecycle]||'');}
function bj04Status(l){
  const miss=bj04Shortage(l);
  if(miss>0) return {label:`Thiếu ${miss} ${l.uom}`,tone:'Warning'};
  if(l.lifecycle==='CONSUMED') return {label:'Đã bàn giao',tone:'Neutral'};
  if(l.lifecycle==='RELEASED') return {label:'Đã giải phóng',tone:'Neutral'};
  if(l.lifecycle==='EXPIRED') return {label:'Đã hết hạn giữ',tone:'Neutral'};
  return {label:'Giữ đủ',tone:'Success'};
}
function bj04Row(l){
  const rem=bj04Remaining(l), held=bj04ActiveHold(l), st=bj04Status(l);
  let summary;
  if(l.lifecycle==='CONSUMED') summary=`${l.code} · Đã bàn giao ${l.consumed} ${l.uom} · Không còn giữ`;
  else if(l.lifecycle==='RELEASED'||l.lifecycle==='EXPIRED') summary=`${l.code} · Không còn cần giữ`;
  else summary=`${l.code} · Đang giữ ${held}/${rem} ${l.uom}`;
  if(l.reservationGroupId) summary+=` · ${l.requested} ${l.uom} theo combo`;
  return ds24ListRow({title:l.name,subtitle:summary,trailing:ds24Badge(st.label,st.tone),leading:'package',type:'Status',interactive:false,density:'Default',extraClass:'bj04-row',attrs:`data-bj04-line="${escapeAttribute(l.id)}" data-lifecycle="${escapeAttribute(l.lifecycle)}"`});
}
function bj04Banner(lines){
  const shortages=lines.filter(l=>bj04Shortage(l)>0);
  const totalHeld=lines.reduce((s,l)=>s+bj04ActiveHold(l),0);
  const totalRemaining=lines.reduce((s,l)=>s+bj04Remaining(l),0);
  if(shortages.length) return vBanner('warning','Chưa giữ đủ',`${shortages.length} dòng còn thiếu. Đơn bán sẽ quyết định bước tiếp theo.`,'','Default');
  if(totalHeld===0&&totalRemaining===0) return vBanner('info','Không còn hàng đang giữ cho đơn này.','Các dòng hiện tại đã được bàn giao, giải phóng hoặc kết thúc.','','Compact');
  return '';
}
const bj04Columns=[
  {key:'productHtml',label:'Sản phẩm',html:true},
  {key:'needHtml',label:'Cần giữ',html:true,align:'end',mono:true},
  {key:'heldHtml',label:'Đang giữ',html:true,align:'end',mono:true},
  {key:'doneHtml',label:'Đã bàn giao',html:true,align:'end',mono:true},
  {key:'missHtml',label:'Thiếu',html:true,align:'end',mono:true},
  {key:'statusHtml',label:'Tình trạng',html:true}
];
function bj04TableRow(l){
  const qty=(n)=>`${n} ${esc(l.uom)}`, term=bj04Terminal(l), st=bj04Status(l), miss=bj04Shortage(l);
  const dash='<span class="k7-muted">—</span>';
  return {line:l,productHtml:`<strong>${esc(l.name)}</strong><small>${esc(l.code)}${l.reservationGroupId?` · ${l.requested} ${esc(l.uom)} theo combo`:''}</small>`,needHtml:term?dash:qty(bj04Remaining(l)),heldHtml:qty(bj04ActiveHold(l)),doneHtml:qty(Number(l.consumed||0)),missHtml:miss>0?`<strong>${qty(miss)}</strong>`:dash,statusHtml:ds24Badge(st.label,st.tone)};
}
function render021BJ04(state){
  state=['READY','LOADING','PERMISSION_DENIED'].includes(state)?state:'READY';
  const m=bj04OrderModel(), title='Giữ hàng theo đơn', subtitle=`Đơn ${m.order} · ${m.customer}`;
  // Mở từ "Xem giữ hàng" ở Hàng cần lấy: nút quay lại về đó, không về Kho (data-keep-back báo cho Hub giữ nguyên nút).
  const keepBack=(html)=>bj04ReturnTo?html.replace('class="app-icon-button app-back-button"','class="app-icon-button app-back-button" data-keep-back'):html;
  const shell=(opts)=>keepBack(appShell({title,subtitle,back:true,backAction:'exit-reservation-context',extraClass:'k7-wide',...opts}));
  if(state==='PERMISSION_DENIED') return shell({body:k1Denied({what:'xem giữ hàng',next:'Liên hệ chủ cửa hàng để được cấp quyền.',exitAttr:k1ExitAttr('SCR-021')}),centered:true});
  if(state==='LOADING') return shell({body:k1Loading({blocks:['heading','row','row','row']})});
  const lines=m.lines;
  const strip=cf12Strip([[lines.filter(l=>bj04ActiveHold(l)>0).length,'đang giữ'],[lines.filter(l=>bj04Shortage(l)>0).length,'thiếu'],[lines.filter(bj04Terminal).length,'đã xong']]);
  const context=`<p class="bj04-context-line k7-mobile-only">${esc(m.warehouse)} · ${esc(m.sourceStatus)} · Có giữ hàng</p>`;
  const table=k7Table({columns:bj04Columns,rows:lines.map(bj04TableRow),mobileRow:(r)=>bj04Row(r.line),caption:'Tình trạng giữ hàng',rowAttr:(r)=>`data-bj04-line="${escapeAttribute(r.line.id)}" data-lifecycle="${escapeAttribute(r.line.lifecycle)}"`});
  const aside=ac310KeyValueSurface('Tóm tắt',[['Đơn',m.order],['Khách hàng',m.customer],['Kho',m.warehouse],['Trạng thái đơn',`${m.sourceStatus} · Có giữ hàng`]]);
  const main=`${context}${strip}${bj04Banner(lines)}<section class="bj04-section" data-ds-component="VSection" data-composed-from="DS v2 / List Row,VBadge">${table}</section>`;
  const body=k7Split({main,aside,wideMain:true,asideWebOnly:true});
  return shell({body,actions:m.pick?primaryFooter('Lấy hàng','data-bj04-go-pick'):''});
}

Object.assign(renderers, { "SCR-021": render021BJ04 });

// Mở 021 cho một đơn (QA / kịch bản golden): như vào từ chi tiết đơn của Theme 5.
Object.assign(window.__VET45_QA__, {
  openBJ04(orderId){ bj04OrderId = String(orderId || bj04StaticModel.order); bj04ReturnTo = null; stateByScreen["SCR-021"] = "READY"; return applyEntry("UIF-04", "order-context", true); }
});

// Quay lại / "Lấy hàng": nghe ở pha bắt để không bị nút quay lại của luồng (về Hub ở chế độ Toàn Theme 7) chặn trước.
document.addEventListener("click", (event) => {
  if (activeFlowId !== "UIF-04") return;
  const t = event.target;
  if (t.closest?.('[data-bj04-go-pick]')) {
    event.preventDefault(); event.stopImmediatePropagation();
    io05SelectedOrderId = bj04OrderId; bj04ReturnTo = null;
    return applyEntry("UIF-05", "order-task", true);
  }
  if (t.closest?.('[data-action="exit-reservation-context"]')) {
    event.preventDefault(); event.stopImmediatePropagation();
    if (bj04ReturnTo === "UIF-05") { bj04ReturnTo = null; return applyEntry("UIF-05", "order-task", true); }
    return showToast(`Quay về đơn bán ${bj04OrderModel().order}`, "info");
  }
}, true);
