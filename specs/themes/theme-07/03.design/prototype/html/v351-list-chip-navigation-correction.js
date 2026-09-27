/* VET45 Theme 7 v3.5.1 — list/chip/navigation correction
 * Parent: v3.5.0. Presentation and drill-down return behavior only.
 */
(function(){
  const patchBackAction=(html,action)=>{
    if(typeof html!=="string") return html;
    const t=document.createElement("template");
    t.innerHTML=html;
    const back=t.content.querySelector(".app-back-button");
    if(back){
      back.removeAttribute("data-back");
      back.setAttribute("data-action",action);
    }
    return t.innerHTML;
  };

  // BJ09 history is an auxiliary drill-down from SCR-037, not the next step after
  // the result screen. Back must restore the detail that launched it without
  // mutating status/result state.
  const base056=renderers["SCR-056"];
  renderers["SCR-056"]=function(state){
    const html=base056(state);
    if(activeFlowId==="UIF-09") return patchBackAction(html,"v351-ic09-history-back");
    if(activeFlowId==="UIF-15") return patchBackAction(html,"v351-cf15-movement-back");
    return html;
  };

  // BJ15 source evidence is another auxiliary drill-down. Make its parent explicit
  // instead of relying on screen-array order.
  const base057=renderers["SCR-057"];
  renderers["SCR-057"]=function(state){
    const html=base057(state);
    if(activeFlowId==="UIF-15") return patchBackAction(html,"v351-cf15-source-back");
    return html;
  };

  document.addEventListener("click",(event)=>{
    const btn=event.target.closest?.("[data-action]");
    if(!btn) return;
    const action=btn.dataset.action;
    if(action==="v351-ic09-history-back" && activeFlowId==="UIF-09"){
      event.preventDefault(); event.stopImmediatePropagation();
      return navigate("SCR-037");
    }
    if(action==="v351-cf15-movement-back" && activeFlowId==="UIF-15"){
      event.preventDefault(); event.stopImmediatePropagation();
      return navigate("SCR-055");
    }
    if(action==="v351-cf15-source-back" && activeFlowId==="UIF-15"){
      event.preventDefault(); event.stopImmediatePropagation();
      return navigate("SCR-056");
    }
  },true);

  if(["UIF-09","UIF-15"].includes(activeFlowId)) render();
})();
