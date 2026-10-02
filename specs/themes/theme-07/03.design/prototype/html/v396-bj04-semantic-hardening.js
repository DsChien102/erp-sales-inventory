/* VET45 Theme 7 v3.9.6 — BJ04 reservation semantic hardening
 * Parent: v3.9.5
 * Approved decisions: T7-DR-144..149 / D04-01..D04-06
 */
(()=>{
  const lines=[
    {id:'RSV-L1',name:'Nobivac DHPPi',code:'SP-000184',uom:'hộp',uomId:'UOM-BOX',uomSnapshot:{label:'hộp',step:1},conversionToBase:10,conversionVersion:'UOM-SP000184-v2',requested:20,reserved:16,consumed:4,policy:'PARTIAL_ALLOWED',priority:10,confirmedAt:'2026-08-27T01:10:00Z',lifecycle:'PARTIALLY_CONSUMED'},
    {id:'RSV-L2',name:'Amox 500',code:'SP-000066',uom:'hộp',uomId:'UOM-BOX',uomSnapshot:{label:'hộp',step:1},conversionToBase:1,conversionVersion:'UOM-SP000066-v1',requested:50,reserved:42,consumed:0,policy:'PARTIAL_ALLOWED',priority:10,confirmedAt:'2026-08-27T01:11:00Z',lifecycle:'ACTIVE'},
    {id:'RSV-G1',name:'Bộ chăm sóc cơ bản',code:'CB-0007',uom:'bộ',uomId:'UOM-COMBO',uomSnapshot:{label:'bộ',step:1},conversionToBase:null,conversionVersion:'COMBO-CB0007-v4',requested:3,reserved:2,consumed:0,policy:'PARTIAL_ALLOWED',priority:20,confirmedAt:'2026-08-27T01:12:00Z',lifecycle:'ACTIVE',reservationGroupId:'RG-CB0007-01',comboDefinitionVersion:4,components:[{product:'SP-000184',qtyPerCombo:2},{product:'SP-000099',qtyPerCombo:1}]},
    {id:'RSV-L4',name:'Vitamin ADE',code:'SP-000099',uom:'chai',uomId:'UOM-BOTTLE',uomSnapshot:{label:'chai',step:1},conversionToBase:1,conversionVersion:'UOM-SP000099-v1',requested:6,reserved:0,consumed:6,policy:'PARTIAL_ALLOWED',priority:10,confirmedAt:'2026-08-27T01:13:00Z',lifecycle:'CONSUMED'}
  ];
  const model={order:'SO-260827-18',warehouse:'Kho chính',inventoryMode:'ADVANCED',reservationPolicy:'PARTIAL_ALLOWED',sourceStatus:'Đã xác nhận',sourceConfirmedAt:'27/08/2026 08:10',lines};
  window.io04V396=model;
  const n=(x)=>Number(x||0);
  const remaining=(l)=>Math.max(0,n(l.requested)-n(l.consumed));
  const shortage=(l)=>Math.max(0,remaining(l)-n(l.reserved));
  const activeHold=(l)=>Math.max(0,n(l.reserved));
  const terminal=(l)=>['CONSUMED','RELEASED','EXPIRED'].includes(l.lifecycle);
  const lifecycleLabel=(l)=>({CONSUMED:'Đã bàn giao',RELEASED:'Đã giải phóng',EXPIRED:'Đã hết hạn giữ',PARTIALLY_CONSUMED:'Đã bàn giao một phần'}[l.lifecycle]||'');
  function row(l){
    const rem=remaining(l), held=activeHold(l), miss=shortage(l);
    let summary='';
    if(l.lifecycle==='CONSUMED') summary=`Đã bàn giao ${l.consumed} ${l.uom} · Không còn giữ`;
    else if(l.lifecycle==='RELEASED'||l.lifecycle==='EXPIRED') summary=`Không còn cần giữ · ${lifecycleLabel(l)}`;
    else summary=`Cần giữ còn lại ${rem} ${l.uom} · Đang giữ ${held} ${l.uom}`;
    if(l.reservationGroupId) summary+=` · ${l.requested} ${l.uom} theo combo`;
    let trailing='';
    if(miss>0) trailing=ds24Badge(`Thiếu ${miss} ${l.uom}`,'Warning');
    else if(l.lifecycle==='CONSUMED') trailing=ds24Badge('Đã bàn giao','Neutral');
    else if(l.lifecycle==='RELEASED') trailing=ds24Badge('Đã giải phóng','Neutral');
    return ds24ListRow({title:`${l.name} · ${l.code}`,subtitle:summary,trailing,leading:'package',type:'Status',interactive:false,density:'Default',extraClass:'v396-reservation-row',attrs:`data-v396-reservation-line="${escapeAttribute(l.id)}" data-lifecycle="${escapeAttribute(l.lifecycle)}"`});
  }
  function banner(){
    const shortages=lines.filter(l=>shortage(l)>0);
    const totalHeld=lines.reduce((s,l)=>s+activeHold(l),0);
    const totalRemaining=lines.reduce((s,l)=>s+remaining(l),0);
    if(shortages.length) return vBanner('warning','Chưa giữ đủ',`${shortages.length} dòng còn thiếu. Đơn bán sẽ quyết định bước tiếp theo.`,'','Default');
    if(totalHeld===0&&totalRemaining===0) return vBanner('info','Không còn hàng đang giữ cho đơn này.','Các dòng hiện tại đã được bàn giao, giải phóng hoặc kết thúc.','','Compact');
    return '';
  }
  function renderV396(state){
    const title='Giữ hàng theo đơn',subtitle=`Đơn ${model.order}`;
    if(state==='PERMISSION_DENIED') return appShell({title,subtitle,body:deniedBody(),centered:true,back:true,backAction:'exit-reservation-context'});
    if(state==='LOADING') return appShell({title,subtitle,body:loadingBody(),back:true,backAction:'exit-reservation-context'});
    const context=ds24InfoGroup('Thông tin đơn',`${ds24InfoRow('Kho',model.warehouse)}${ds24InfoRow('Trạng thái đơn',`${model.sourceStatus} · Có giữ hàng`)}`,'bj04-context');
    const rows=lines.map(row).join('');
    const activeCount=lines.filter(l=>activeHold(l)>0).length;
    const body=`${context}${banner()}<section class="bj04-section v396-reservation-section" data-ds-component="VSection" data-composed-from="DS v2 / List Row,VBadge">${ds24SectionTitle('Tình trạng giữ hàng',`${activeCount} dòng đang giữ`)}<div class="bj04-list-stack">${rows}</div></section>`;
    return appShell({title,subtitle,body,back:true,backAction:'exit-reservation-context'});
  }
  render021IO04=function(state){
    if(activeFlowId!=='UIF-04') return renderGeneric(screens.find(s=>s.id==='SCR-021'),state);
    return renderV396(['READY','LOADING','PERMISSION_DENIED'].includes(state)?state:'READY');
  };
  if(typeof renderers!=='undefined') renderers['SCR-021']=render021IO04;

  // Product catalog: contextual capability only when the source order actually owns a reservation context.
  const priorRenderAppScreen=renderAppScreen;
  renderAppScreen=function(){
    priorRenderAppScreen();
    const contextual=document.querySelector('#app-screen [data-t381-catalog-flow="UIF-04"]');
    if(contextual){
      contextual.setAttribute('disabled',''); contextual.setAttribute('aria-disabled','true'); contextual.setAttribute('data-ds-prop-state','Disabled'); contextual.removeAttribute('data-theme-entry-flow');
      const helper=contextual.querySelector('.ds24-list-row__copy small'); if(helper) helper.textContent='Chỉ mở từ đơn có giữ hàng';
    }
  };
  if(window.__VET45_PROTOTYPE__) window.__VET45_PROTOTYPE__.version='3.9.6';
})();
