/* VET45 Theme 7 v3.6.1 — dual Sticky Footer normalization
 * Parent: v3.6.0
 * Scope: UI-only correction. No business rule, action, state or navigation change.
 */
(() => {
  const VERSION = "3.6.1";

  function directButtons(footer){
    return [...footer.children].filter((el)=>el.tagName === "BUTTON" && el.offsetParent !== null);
  }
  function isPrimary(button){
    return button.classList.contains("button--primary") || button.classList.contains("ds24-button--primary");
  }
  function isDanger(button){
    return button.classList.contains("button--danger") ||
      button.classList.contains("ds24-button--danger") ||
      button.classList.contains("ac310-danger-text") ||
      button.classList.contains("v360-session-cancel") ||
      button.dataset.dsPropTone === "VComponentTone.danger" ||
      button.dataset.dsProfile === "button.destructiveSecondary";
  }
  function hasDestructiveIntent(button){
    if(isDanger(button)) return true;
    const actionMetadata=Object.entries(button.dataset || {})
      .filter(([key])=>/action|intent|profile/i.test(key))
      .map(([,value])=>String(value || ""))
      .join(" ");
    return /(^|[-_\s])(reject|cancel|delete|remove|destructive)([-_\s]|$)/i.test(actionMetadata);
  }

  function normalizeDualFooters(){
    const root=document.getElementById("app-screen");
    if(!root) return;
    root.querySelectorAll(".app-actions").forEach((footer)=>{
      const buttons=directButtons(footer);
      footer.classList.remove("v361-dual-footer","v361-dual-footer--danger");
      if(buttons.length !== 2) return;

      const primary=buttons.find(isPrimary);
      const secondary=buttons.find((b)=>b !== primary);
      // DS convention is Secondary/Destructive | Primary. Keep DOM/tab order aligned with visual order.
      if(primary && secondary && footer.firstElementChild !== secondary){
        footer.insertBefore(secondary, primary);
      }

      // Destructive intent (reject/cancel/delete/remove) uses the canonical danger secondary hierarchy.
      if(secondary && hasDestructiveIntent(secondary) && !isPrimary(secondary)){
        secondary.dataset.dsPropTone="VComponentTone.danger";
        secondary.dataset.dsProfile="button.destructiveSecondary";
      }

      footer.classList.add("v361-dual-footer");
      footer.dataset.dsPropLayout="Dual";
      const tone=buttons.some(isDanger) ? "Danger" : "Default";
      footer.dataset.dsPropTone=tone;
      if(tone === "Danger") footer.classList.add("v361-dual-footer--danger");
    });
  }

  const previousRenderAppScreen=renderAppScreen;
  renderAppScreen=function(){
    const out=previousRenderAppScreen();
    normalizeDualFooters();
    return out;
  };

  // Normalize the screen already rendered by the previous release script.
  normalizeDualFooters();

  if(window.__VET45_PROTOTYPE__){
    window.__VET45_PROTOTYPE__.version=VERSION;
    window.__VET45_PROTOTYPE__.scenarios=[...(window.__VET45_PROTOTYPE__.scenarios||[]),"dual-footer-horizontal"];
  }
  window.__VET45_V361__={version:VERSION,normalizeDualFooters};
})();
