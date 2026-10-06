/* VET45 Theme 7 v4.6.6 — BJ02 Quick Receipt no-draft alignment
 * Business behavior is implemented in canonical BJ02 renderers/contracts.
 * This finalizer only publishes the candidate version/scenario to the review runtime.
 */
(()=>{
  const VERSION='4.6.6';
  const badge=document.querySelector('.review-meta > .review-badge:not(.review-badge--muted)');
  if(badge)badge.textContent='v4.6.6 · BJ02 Quick Receipt no draft';
  if(window.__VET45_PROTOTYPE__){
    window.__VET45_PROTOTYPE__.version=VERSION;
    window.__VET45_PROTOTYPE__.scenarios=[...new Set([...(window.__VET45_PROTOTYPE__.scenarios||[]),'bj02-quick-receipt-no-draft'])];
    window.__VET45_PROTOTYPE__.bj02QuickReceipt={draftPersistence:false,firstPersistedState:'PENDING_APPROVAL',receiptIdCreatedOnSuccessfulSubmit:true};
  }
})();
