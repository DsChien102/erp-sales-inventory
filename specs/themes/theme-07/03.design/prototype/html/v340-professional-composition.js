/* VET45 Theme 7 v3.4.0 — professional composition correction
 * Parent: v3.3.0
 * Scope: cumulative product/context hierarchy cleanup, with targeted renderer changes in BJ08.
 * No business/state/action contract is changed.
 */

// Keep product identity quiet during counting: the screen already communicates the task.
ac310CountGroup = function({id,name,code,lot,uom,value,unexpected=false,disabled=false}){
  const parent=ac310ProductRow({
    name, code,
    meta:`${lot?`Lô ${lot} · `:""}${uom}`,
    badge:unexpected?"Bổ sung thực tế":"",
    tone:unexpected?"Info":"Neutral",
    status:true
  });
  return `<section class="ac310-product-control-group ac340-product-task" data-layout-pattern="Grouped surface" data-composed-from="DS v2 / List Row,VNumericKeypadSheet">${parent}<div class="ac310-control-indent">${ic08QuantityTrigger("Số lượng thực tế",value,`count:${id}`,uom,disabled)}</div></section>`;
};

// Variance is evidence, not a status badge. Put all numeric comparison facts in one aligned region.
ac310RecountGroup = function({id,name,code,lot,uom,book,first,variance,value,disabled=false}){
  const parent=ac310ProductRow({name,code,meta:`Lô ${lot} · ${uom}`,badge:"",tone:"Neutral",status:true});
  const facts=ac310KeyValueSurface("",[
    ["Theo sổ",`${book} ${uom}`],
    ["Lần đếm đầu",`${first} ${uom}`],
    ["Chênh lệch",variance]
  ],{extraClass:"ac310-inline-surface ac340-recount-facts"});
  return `<section class="ac310-product-control-group ac340-product-task ac340-recount-task" data-layout-pattern="Grouped surface" data-composed-from="DS v2 / List Row,DS v2 / Key-value Row,VNumericKeypadSheet">${parent}<div class="ac310-control-indent">${facts}${ic08QuantityTrigger("Số lượng đếm lại",value,`recount:${id}`,uom,disabled)}</div></section>`;
};

function ac340ReviewProduct({name,code,meta,variance,rows}){
  const product=ac310ProductRow({name,code,meta,badge:"",tone:"Neutral",status:true});
  const details=ac310KeyValueSurface("",[["Chênh lệch",variance],...rows],{extraClass:"ac310-approval-detail ac340-review-facts"});
  return `<section class="ac340-review-group" data-layout-pattern="Grouped surface" data-composed-from="DS v2 / List Row,DS v2 / Key-value Row">${product}${details}</section>`;
}

const ac340Base044=renderers["SCR-044"];
const ac340Base045=renderers["SCR-045"];
const ac340Base046=renderers["SCR-046"];

function ac340Render044(state){
  if(activeFlowId!=="UIF-08" || !["BLIND_COUNT","READY","VALIDATION_ERROR","LOCK_LOST"].includes(state)) return ac340Base044(state);
  const lost=state==="LOCK_LOST";
  const error=state==="VALIDATION_ERROR"?vBanner("error","Chưa nhập đủ kết quả","Nhập số đếm thực tế cho tất cả dòng trước khi nộp."):"";
  const notice=lost?vBanner("warning","Phiên không còn giữ khóa","Số đã nhập được giữ trên thiết bị. Quay về phiên kiểm kê để tải lại trạng thái hiện hành trước khi tiếp tục."):vBanner("info","Đang đếm mù","Chỉ nhập số thực tế. Số theo sổ và chênh lệch chỉ hiển thị sau lần nộp đầu.");
  const groups=[
    ac310CountGroup({id:"amox",name:"Amox 500",code:"SP-00128",lot:"L2407-A",uom:"hộp",value:ic08Counts.amox,disabled:lost}),
    ac310CountGroup({id:"glove",name:"Găng tay M",code:"SP-00410",lot:"L2405-M",uom:"hộp",value:ic08Counts.glove,disabled:lost})
  ];
  if(ic08UnexpectedLine) groups.push(ac310CountGroup({id:"unexpected",name:ic08UnexpectedLine.name,code:"Hàng thực tế bổ sung",lot:ic08UnexpectedLine.lot,uom:ic08UnexpectedLine.uom,value:ic08UnexpectedLine.value,unexpected:true,disabled:lost}));
  const body=`${error}${notice}${ac310InfoSurface("Phiên kiểm kê",[["Mã phiên","KK-0709-03"],["Kho","Kho trung tâm"],["Thời điểm chốt","09/09/2026 · 08:00"]])}<div class="ac310-product-control-list ac340-product-task-list">${groups.join("")}</div>${!lost?`<button class="button button--secondary ac310-inline-button" type="button" data-ic08-action="add-actual-open" data-ds-component="VButton">Thêm hàng thực tế</button>`:""}${ic08Overlays()}`;
  return ac310Return(appShell({title:"Đếm mù",body,actions:lost?primaryFooter("Về phiên kiểm kê",'data-ic08-action="to-list"'):primaryFooter("Nộp kết quả đếm",'data-ic08-action="submit-first"')}));
}

function ac340Render045(state){
  if(activeFlowId!=="UIF-08" || !["RECOUNT_REQUIRED","READY","LOCKED","PRICE_BASIS_REQUIRED","EVIDENCE_REQUIRED","VALIDATION_ERROR"].includes(state)) return ac340Base045(state);
  const locked=state==="LOCKED",price=state==="PRICE_BASIS_REQUIRED",evidence=state==="EVIDENCE_REQUIRED";
  const notice=locked?vBanner("warning","Phiên đang chỉ đọc","Không thể sửa kết quả đếm trong trạng thái hiện hành."):price?vBanner("error","Chưa đủ căn cứ giá","Dòng thừa chưa có căn cứ giá hợp lệ. Phiên vẫn được giữ khóa."):evidence?vBanner("warning","Chưa đủ bằng chứng","Bổ sung bằng chứng cần thiết trước khi gửi duyệt."):state==="VALIDATION_ERROR"?vBanner("error","Kết quả đếm lại chưa hợp lệ","Kiểm tra số lượng đếm lại trước khi gửi."):vBanner("info","Chỉ đếm lại dòng có chênh lệch","Số theo sổ đã được hiển thị sau lần đếm đầu.");
  const groups=[
    ac310RecountGroup({id:"amox",name:"Amox 500",code:"SP-00128",lot:"L2407-A",uom:"hộp",book:20,first:18,variance:"−2 hộp",value:ic08Recounts.amox,disabled:locked}),
    ac310RecountGroup({id:"glove",name:"Găng tay M",code:"SP-00410",lot:"L2405-M",uom:"hộp",book:6,first:7,variance:"+1 hộp",value:ic08Recounts.glove,disabled:locked})
  ];
  const evidenceRows=[["Amox 500","Đã có bằng chứng"],["Găng tay M",price?"Thiếu căn cứ giá":evidence?"Thiếu bằng chứng":"Đã có căn cứ"]];
  const body=`${notice}<div class="ac310-product-control-list ac340-product-task-list">${groups.join("")}</div>${ac310InfoSurface("Căn cứ và bằng chứng",evidenceRows)}${(price||evidence)?vBanner("warning","Chưa thể gửi duyệt","Chỉ có thể gửi khi tất cả căn cứ bắt buộc đã hợp lệ."):""}${ic08Overlays()}`;
  let actions=""; if(!locked) actions=`<footer class="app-actions figma-sticky-footer ac310-footer-stack"><button class="button button--primary" type="button" data-ic08-action="submit-recount" data-ds-component="VButton" ${price||evidence?'disabled':''}>Gửi chờ duyệt</button>${price||evidence?`<button class="button button--secondary ac310-danger-text" type="button" data-ic08-action="cancel-open" data-ds-component="VButton">Hủy phiên</button>`:""}</footer>`;
  return ac310Return(appShell({title:"Chênh lệch và đếm lại",body,actions}));
}

function ac340Render046(state){
  if(activeFlowId!=="UIF-08" || !["READY","APPROVAL_REVIEW"].includes(state)) return ac340Base046(state);
  const products=`<div class="ac340-review-list">${ac340ReviewProduct({name:"Amox 500",code:"SP-00128",meta:"Lô L2407-A · hộp",variance:"−2 hộp",rows:[["Đếm lại","18 hộp"],["Bằng chứng","Đã đủ"]]})}${ac340ReviewProduct({name:"Găng tay M",code:"SP-00410",meta:"Lô L2405-M · hộp",variance:"+1 hộp",rows:[["Đếm lại","7 hộp"],["Căn cứ giá","Đã đủ"],["Bằng chứng","Đã đủ"]]})}</div>`;
  const body=`${vBanner("info","Cần quyết định độc lập","Người duyệt chỉ rà soát bằng chứng và quyết định; không sửa số đếm.")}${ac310InfoSurface("Phiên kiểm kê",[["Mã phiên","KK-0709-03",true],["Người thực hiện","Nguyễn An"],["Kho","Kho trung tâm"],["Dòng chênh lệch","2 dòng"]])}${products}${ic08Overlays()}`;
  const actions=`<footer class="app-actions figma-sticky-footer ac310-two-actions"><button class="button button--secondary" type="button" data-ic08-action="request-review" data-ds-component="VButton">Yêu cầu xem lại</button><button class="button button--primary" type="button" data-ic08-action="approve" data-ds-component="VButton">Duyệt và điều chỉnh</button></footer>`;
  return ac310Return(appShell({title:"Duyệt kiểm kê",body,actions}));
}

renderers["SCR-044"]=ac340Render044;
renderers["SCR-045"]=ac340Render045;
renderers["SCR-046"]=ac340Render046;

if(activeFlowId==="UIF-08") render();
