/* VET45 Theme 7 v3.6.3 — homogeneous list navigation / disabled-state correction
 * Parent: v3.6.2
 * UI semantics only: non-actionable peers in a navigation collection keep Navigation anatomy
 * and chevron, using the canonical Disabled state instead of switching component Type.
 */
(()=>{
  const VERSION = "3.6.3";
  if(window.__VET45_PROTOTYPE__){
    window.__VET45_PROTOTYPE__.version = VERSION;
    window.__VET45_PROTOTYPE__.scenarios = [
      ...(window.__VET45_PROTOTYPE__.scenarios || []),
      "homogeneous-navigation-list-disabled-state"
    ];
  }
})();
