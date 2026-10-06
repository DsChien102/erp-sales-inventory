/* VET45 Theme 7 v4.6.7 — BJ02 Quick approval does not depend on price/FX basis. */
(()=>{
  const VERSION='4.6.7';
  const badge=document.querySelector('.review-meta > .review-badge:not(.review-badge--muted)');
  if(badge)badge.textContent='v4.6.7 · BJ02 Quick approval no price basis';
  if(window.__VET45_PROTOTYPE__){
    window.__VET45_PROTOTYPE__.version=VERSION;
    window.__VET45_PROTOTYPE__.scenarios=[...new Set([...(window.__VET45_PROTOTYPE__.scenarios||[]),'bj02-quick-approval-no-price-basis'])];
    window.__VET45_PROTOTYPE__.bj02QuickReceipt={...(window.__VET45_PROTOTYPE__.bj02QuickReceipt||{}),draftPersistence:false,firstPersistedState:'PENDING_APPROVAL',receiptIdCreatedOnSuccessfulSubmit:true,priceFxRequiredAtBj02Submit:false};
  }
})();
