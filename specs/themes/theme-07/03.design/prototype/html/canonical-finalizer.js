(() => {
  'use strict';
  const renderer = window.VET45_CANONICAL_RENDERER;
  const host = document.getElementById('app-screen');
  if (!renderer || !host) return;
  let scheduled = false;
  let normalizing = false;

  function finalize(reason='render') {
    if (normalizing) return;
    const product = host.firstElementChild;
    if (!product) return;
    normalizing = true;
    try {
      renderer.normalizeShell(product);
      renderer.canonicalize(product);
      product.dataset.htmlDsVersion = '1.6.0';
      product.dataset.rendererVersion = '5.4.0';
      host.dispatchEvent(new CustomEvent('vet45canonicalrender', {
        detail: {
          screenId: typeof activeScreenId === 'string' ? activeScreenId : null,
          state: typeof stateByScreen === 'object' && typeof activeScreenId === 'string' ? stateByScreen[activeScreenId] : null,
          flowId: typeof activeFlowId === 'string' ? activeFlowId : null,
          finalizer: true,
          reason
        }, bubbles: true
      }));
    } finally { normalizing = false; }
  }
  function schedule(reason) {
    if (scheduled || normalizing) return;
    scheduled = true;
    queueMicrotask(() => { scheduled = false; finalize(reason); });
  }

  if (typeof window.renderAppScreen === 'function') {
    const previous = window.renderAppScreen;
    window.renderAppScreen = function(...args) {
      const result = previous.apply(this,args);
      finalize('renderAppScreen');
      return result;
    };
  }
  const observer = new MutationObserver((records) => {
    if (normalizing) return;
    const structural = records.some((r) => {
      if (r.type !== 'childList') return false;
      if (r.target === host) return true;
      const nodes = [...r.addedNodes, ...r.removedNodes].filter((n) => n.nodeType === 1);
      return nodes.some((node) =>
        node.matches?.('.v-page-scaffold,.app-appbar,.app-content,[data-mobile-product]') ||
        node.querySelector?.('.v-page-scaffold,.app-appbar,.app-content')
      );
    });
    if (structural) schedule('structural-mutation');
  });
  observer.observe(host,{subtree:true,childList:true});
  const badge=document.querySelector('.review-meta > .review-badge:not(.review-badge--muted)');
  if (badge) badge.textContent='v5.4.0 · Cumulative Theme 7 · HTML DS 1.6';
  if (window.__VET45_PROTOTYPE__) window.__VET45_PROTOTYPE__.version='5.4.0';
  finalize('boot');
})();
