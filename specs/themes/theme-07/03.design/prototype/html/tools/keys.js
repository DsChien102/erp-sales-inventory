(() => {
  const dialog = document.querySelector('#app-screen [role="dialog"]');
  if (!dialog) return { keys: null };
  const items = () => [...dialog.querySelectorAll("button:not([disabled]), [href], input, textarea, select, [tabindex]:not([tabindex='-1'])")].filter((el) => el.offsetParent !== null);
  const press = (key, shiftKey = false) => window.dispatchEvent(new KeyboardEvent('keydown', { key, shiftKey, bubbles: true, cancelable: true }));
  const list = items(); const r = { items: list.length, tabWrap: null, shiftTabWrap: null, escCloses: null };
  if (list.length) {
    list[list.length - 1].focus(); press('Tab'); r.tabWrap = document.activeElement === list[0];
    list[0].focus(); press('Tab', true); r.shiftTabWrap = document.activeElement === list[list.length - 1];
  }
  press('Escape'); r.escCloses = !document.querySelector('#app-screen [role="dialog"]');
  return { keys: r };
})()
