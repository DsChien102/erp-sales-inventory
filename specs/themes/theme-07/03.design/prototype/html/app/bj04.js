/* BJ-04 — Quản lý vòng đời giữ hàng (UIF-04). Màn: SCR-021.
 *
 * Đã viết lại sạch (T7-P gói A1, 2026-10-17): mọi hàm dựng, fixture và xử lý sự kiện của BJ-04 nằm ở đây.
 * Sửa BJ-04: sửa thẳng file này.
 * Dùng chung từ app/core.js: appShell, ds24ListRow, ds24Badge, ds24InfoGroup, ds24InfoRow, ds24SectionTitle,
 * vBanner, deniedBody, loadingBody, escapeAttribute, showToast.
 */

// ---- Fixture và trạng thái
const bj04Lines = [
  {id:'RSV-L1',name:'Nobivac DHPPi',code:'SP-000184',uom:'hộp',uomId:'UOM-BOX',uomSnapshot:{label:'hộp',step:1},conversionToBase:10,conversionVersion:'UOM-SP000184-v2',requested:20,reserved:16,consumed:4,policy:'PARTIAL_ALLOWED',priority:10,confirmedAt:'2026-08-27T01:10:00Z',lifecycle:'PARTIALLY_CONSUMED'},
  {id:'RSV-L2',name:'Amox 500',code:'SP-000066',uom:'hộp',uomId:'UOM-BOX',uomSnapshot:{label:'hộp',step:1},conversionToBase:1,conversionVersion:'UOM-SP000066-v1',requested:50,reserved:42,consumed:0,policy:'PARTIAL_ALLOWED',priority:10,confirmedAt:'2026-08-27T01:11:00Z',lifecycle:'ACTIVE'},
  {id:'RSV-G1',name:'Bộ chăm sóc cơ bản',code:'CB-0007',uom:'bộ',uomId:'UOM-COMBO',uomSnapshot:{label:'bộ',step:1},conversionToBase:null,conversionVersion:'COMBO-CB0007-v4',requested:3,reserved:2,consumed:0,policy:'PARTIAL_ALLOWED',priority:20,confirmedAt:'2026-08-27T01:12:00Z',lifecycle:'ACTIVE',reservationGroupId:'RG-CB0007-01',comboDefinitionVersion:4,components:[{product:'SP-000184',qtyPerCombo:2},{product:'SP-000099',qtyPerCombo:1}]},
  {id:'RSV-L4',name:'Vitamin ADE',code:'SP-000099',uom:'chai',uomId:'UOM-BOTTLE',uomSnapshot:{label:'chai',step:1},conversionToBase:1,conversionVersion:'UOM-SP000099-v1',requested:6,reserved:0,consumed:6,policy:'PARTIAL_ALLOWED',priority:10,confirmedAt:'2026-08-27T01:13:00Z',lifecycle:'CONSUMED'}
];
const bj04Model = {order:'SO-260827-18',warehouse:'Kho chính',inventoryMode:'ADVANCED',reservationPolicy:'PARTIAL_ALLOWED',sourceStatus:'Đã xác nhận',sourceConfirmedAt:'27/08/2026 08:10',lines:bj04Lines};

function bj04Remaining(l){return Math.max(0,Number(l.requested||0)-Number(l.consumed||0));}
function bj04Shortage(l){return Math.max(0,bj04Remaining(l)-Number(l.reserved||0));}
function bj04ActiveHold(l){return Math.max(0,Number(l.reserved||0));}
function bj04Terminal(l){return ['CONSUMED','RELEASED','EXPIRED'].includes(l.lifecycle);}
function bj04LifecycleLabel(l){return ({CONSUMED:'Đã bàn giao',RELEASED:'Đã giải phóng',EXPIRED:'Đã hết hạn giữ',PARTIALLY_CONSUMED:'Đã bàn giao một phần'}[l.lifecycle]||'');}
function bj04Row(l){
  const rem=bj04Remaining(l), held=bj04ActiveHold(l), miss=bj04Shortage(l);
  let summary='';
  if(l.lifecycle==='CONSUMED') summary=`Đã bàn giao ${l.consumed} ${l.uom} · Không còn giữ`;
  else if(l.lifecycle==='RELEASED'||l.lifecycle==='EXPIRED') summary=`Không còn cần giữ · ${bj04LifecycleLabel(l)}`;
  else summary=`Cần giữ còn lại ${rem} ${l.uom} · Đang giữ ${held} ${l.uom}`;
  if(l.reservationGroupId) summary+=` · ${l.requested} ${l.uom} theo combo`;
  let trailing='';
  if(miss>0) trailing=ds24Badge(`Thiếu ${miss} ${l.uom}`,'Warning');
  else if(l.lifecycle==='CONSUMED') trailing=ds24Badge('Đã bàn giao','Neutral');
  else if(l.lifecycle==='RELEASED') trailing=ds24Badge('Đã giải phóng','Neutral');
  return ds24ListRow({title:`${l.name} · ${l.code}`,subtitle:summary,trailing,leading:'package',type:'Status',interactive:false,density:'Default',extraClass:'v396-reservation-row',attrs:`data-v396-reservation-line="${escapeAttribute(l.id)}" data-lifecycle="${escapeAttribute(l.lifecycle)}"`});
}
function bj04Banner(){
  const shortages=bj04Lines.filter(l=>bj04Shortage(l)>0);
  const totalHeld=bj04Lines.reduce((s,l)=>s+bj04ActiveHold(l),0);
  const totalRemaining=bj04Lines.reduce((s,l)=>s+bj04Remaining(l),0);
  if(shortages.length) return vBanner('warning','Chưa giữ đủ',`${shortages.length} dòng còn thiếu. Đơn bán sẽ quyết định bước tiếp theo.`,'','Default');
  if(totalHeld===0&&totalRemaining===0) return vBanner('info','Không còn hàng đang giữ cho đơn này.','Các dòng hiện tại đã được bàn giao, giải phóng hoặc kết thúc.','','Compact');
  return '';
}
function render021BJ04(state){
  state=['READY','LOADING','PERMISSION_DENIED'].includes(state)?state:'READY';
  const title='Giữ hàng theo đơn',subtitle=`Đơn ${bj04Model.order}`;
  if(state==='PERMISSION_DENIED') return appShell({title,subtitle,body:deniedBody(),centered:true,back:true,backAction:'exit-reservation-context'});
  if(state==='LOADING') return appShell({title,subtitle,body:loadingBody(),back:true,backAction:'exit-reservation-context'});
  const context=ds24InfoGroup('Thông tin đơn',`${ds24InfoRow('Kho',bj04Model.warehouse)}${ds24InfoRow('Trạng thái đơn',`${bj04Model.sourceStatus} · Có giữ hàng`)}`,'bj04-context');
  const rows=bj04Lines.map(bj04Row).join('');
  const activeCount=bj04Lines.filter(l=>bj04ActiveHold(l)>0).length;
  const body=`${context}${bj04Banner()}<section class="bj04-section v396-reservation-section" data-ds-component="VSection" data-composed-from="DS v2 / List Row,VBadge">${ds24SectionTitle('Tình trạng giữ hàng',`${activeCount} dòng đang giữ`)}<div class="bj04-list-stack">${rows}</div></section>`;
  return appShell({title,subtitle,body,back:true,backAction:'exit-reservation-context'});
}

Object.assign(renderers, { "SCR-021": render021BJ04 });

document.addEventListener("click", (event) => {
  if (activeFlowId !== "UIF-04") return;
  if (event.target.closest('[data-action="exit-reservation-context"]')) return showToast(`Quay về đơn bán ${bj04Model.order}`, "info");
});
