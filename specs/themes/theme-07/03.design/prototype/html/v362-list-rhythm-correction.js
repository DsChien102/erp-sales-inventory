/* VET45 Theme 7 v3.6.2 — independent list/card rhythm correction
 * Layout-only cumulative release. No business/state/action/navigation mutation.
 */
(()=>{
  const VERSION = "3.6.2";
  if(window.__VET45_PROTOTYPE__){
    window.__VET45_PROTOTYPE__.version = VERSION;
    window.__VET45_PROTOTYPE__.scenarios = [
      ...(window.__VET45_PROTOTYPE__.scenarios || []),
      "independent-list-card-rhythm"
    ];
  }
})();
