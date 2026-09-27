/* VET45 Theme 7 v4.4.0 — theme-wide grouped information surface normalization */
(()=>{
  const VERSION='4.4.0';
  const ROW_SELECTOR='[data-ds-component="DS v2 / Info Row"],[data-ds-component="DS v2 / Key-value Row"]';
  const ROOT_BOUNDARY_SELECTOR='#app-screen,.app-content,.app-body,.app-shell,.device-screen';
  const alpha=(value)=>{
    const text=String(value||'');
    if(!text||text==='transparent') return 0;
    const m=text.match(/rgba?\(([^)]+)\)/i);
    if(!m) return 1;
    const parts=m[1].split(',').map(v=>v.trim());
    return parts.length<4?1:Number(parts[3]);
  };
  const hasVisualSurface=(el)=>{
    if(!el) return false;
    const s=getComputedStyle(el);
    const borderWidths=[s.borderTopWidth,s.borderRightWidth,s.borderBottomWidth,s.borderLeftWidth].map(v=>parseFloat(v)||0);
    const hasBorder=borderWidths.some(v=>v>0.1) && [s.borderTopStyle,s.borderRightStyle,s.borderBottomStyle,s.borderLeftStyle].some(v=>v!=='none');
    const hasShadow=Boolean(s.boxShadow&&s.boxShadow!=='none');
    const hasBackground=alpha(s.backgroundColor)>0.01;
    return hasBorder||hasShadow||hasBackground;
  };
  const alreadyOwnedBySurface=(stack)=>{
    let current=stack;
    for(let depth=0;current&&depth<3;depth+=1,current=current.parentElement){
      if(depth>0 && current.matches?.(ROOT_BOUNDARY_SELECTOR)) break;
      if(hasVisualSurface(current)) return true;
    }
    return false;
  };
  const isMinimalRowStack=(el)=>{
    const direct=[...el.children].filter(child=>child.matches?.(ROW_SELECTOR));
    if(direct.length<2) return false;
    return ![...el.children].some(child=>[...child.children].filter(grand=>grand.matches?.(ROW_SELECTOR)).length>=2);
  };
  function applyGroupedSurfaceRule(){
    const root=document.querySelector('#app-screen');
    if(!root) return {candidates:0,added:0};
    let candidates=0,added=0;
    root.querySelectorAll('*').forEach((el)=>{
      if(!isMinimalRowStack(el)) return;
      candidates+=1;
      if(alreadyOwnedBySurface(el)) return;
      el.classList.add('v440-grouped-surface');
      el.setAttribute('data-layout-pattern','Grouped surface');
      el.setAttribute('data-v440-grouped-surface','auto');
      added+=1;
    });
    return {candidates,added};
  }
  const priorRenderAppScreen=typeof renderAppScreen==='function'?renderAppScreen:null;
  if(priorRenderAppScreen){
    renderAppScreen=function(){
      const out=priorRenderAppScreen.apply(this,arguments);
      applyGroupedSurfaceRule();
      return out;
    };
  }
  const priorRender=typeof render==='function'?render:null;
  if(priorRender){
    render=function(){
      const out=priorRender.apply(this,arguments);
      applyGroupedSurfaceRule();
      return out;
    };
  }
  const root=document.querySelector('#app-screen');
  if(root && typeof MutationObserver!=='undefined'){
    let scheduled=false;
    const observer=new MutationObserver(()=>{
      if(scheduled) return;
      scheduled=true;
      queueMicrotask(()=>{scheduled=false;applyGroupedSurfaceRule();});
    });
    observer.observe(root,{childList:true,subtree:true});
  }
  applyGroupedSurfaceRule();
  if(window.__VET45_PROTOTYPE__) window.__VET45_PROTOTYPE__.version=VERSION;
  window.__VET45_V440__={version:VERSION,parent:'4.3.1',scope:'ALL_CANONICAL_UIF',rule:'ONE_HOMOGENEOUS_COLLECTION_ONE_SURFACE_BOUNDARY',applyGroupedSurfaceRule};
})();
