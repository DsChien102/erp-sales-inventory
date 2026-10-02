/* Theme 7 presentation adapter for VET45 HTML Design System v1.5.0.
   It only adds canonical DS classes/data attributes inside the product viewport. */

const HTML_DS_VERSION = "1.5.0";

function normalizeDsValue(value) {
  return String(value || "").split(".").pop().trim().toLowerCase();
}

function addCanonicalClass(element, className) {
  if (element && className) element.classList.add(className);
}

function directElementChildren(element) {
  return element ? [...element.children].filter((child) => child.nodeType === 1) : [];
}

function alignHtmlDesignSystem(root) {
  if (!root) return;
  const product = root.matches?.("[data-mobile-product]") ? root : root.querySelector?.("[data-mobile-product]");
  if (!product) return;
  product.dataset.htmlDsVersion = HTML_DS_VERSION;

  product.querySelectorAll('[data-ds-component="VAppBar"]').forEach((el) => addCanonicalClass(el, "v-appbar"));
  product.querySelectorAll('.app-back-button,[data-ds-component="DS v2 / Icon Button"]').forEach((el) => addCanonicalClass(el, "v-icon-btn"));

  product.querySelectorAll('[data-ds-component="VButton"],.button,.ds24-button').forEach((el) => {
    addCanonicalClass(el, "v-btn");
    const rawVariant = normalizeDsValue(el.dataset.dsPropHierarchy || el.dataset.dsPropVariant);
    const rawTone = normalizeDsValue(el.dataset.dsPropTone);
    let hierarchy = rawVariant;
    if (!['primary','secondary','tertiary','danger'].includes(hierarchy)) {
      if (el.classList.contains('button--primary') || el.classList.contains('ds24-button--primary')) hierarchy = 'primary';
      else if (el.classList.contains('button--secondary') || el.classList.contains('ds24-button--secondary')) hierarchy = 'secondary';
      else if (el.classList.contains('button--tertiary') || el.classList.contains('ds24-button--tertiary')) hierarchy = 'tertiary';
      else hierarchy = 'secondary';
    }
    if (rawTone === 'danger' || el.classList.contains('button--danger') || el.classList.contains('is-danger')) hierarchy = 'danger';
    el.dataset.hierarchy = hierarchy;
    const size = normalizeDsValue(el.dataset.dsPropSize || el.dataset.size) || (el.classList.contains('button--small') ? 'small' : el.classList.contains('button--large') ? 'large' : 'default');
    el.dataset.size = ['small','large'].includes(size) ? size : 'default';
    if (el.disabled || el.getAttribute('aria-disabled') === 'true') el.dataset.state = 'disabled';
  });

  product.querySelectorAll('[data-ds-component="VBadge"],.status-badge,.ds24-badge').forEach((el) => {
    addCanonicalClass(el, "v-badge");
    let tone = normalizeDsValue(el.dataset.dsPropTone || el.dataset.dsPropStatus);
    if (!tone || tone === 'neutral' || tone === 'default') {
      if (el.className.includes('success')) tone = 'success';
      else if (el.className.includes('warning')) tone = 'warning';
      else if (el.className.includes('danger') || el.className.includes('error')) tone = 'danger';
      else if (el.className.includes('info')) tone = 'info';
      else tone = 'neutral';
    }
    el.dataset.tone = tone;
  });

  product.querySelectorAll('[data-ds-component="VChip"],.ds24-chip').forEach((el) => {
    addCanonicalClass(el, "v-chip");
    const selected = el.classList.contains('is-selected') || el.getAttribute('aria-pressed') === 'true' || normalizeDsValue(el.dataset.dsPropSelected) === 'true';
    let tone = normalizeDsValue(el.dataset.dsPropTone);
    if (!tone || tone === 'neutral') tone = selected ? 'brand' : 'neutral';
    el.dataset.tone = tone;
    if (el.disabled || el.getAttribute('aria-disabled') === 'true') el.dataset.state = 'disabled';
  });

  product.querySelectorAll('[data-ds-component="DS v2 / List Row"],.ds24-list-row').forEach((el) => {
    addCanonicalClass(el, "v-list-row");
    const density = normalizeDsValue(el.dataset.dsPropDensity) || 'default';
    const state = normalizeDsValue(el.dataset.dsPropState) || 'default';
    const type = normalizeDsValue(el.dataset.dsPropType) || 'navigation';
    el.dataset.density = density;
    el.dataset.state = state;
    el.dataset.type = type;
    const copy = el.querySelector('.ds24-list-row__copy');
    if (copy) {
      addCanonicalClass(copy, 'v-list-row__copy');
      addCanonicalClass(copy.querySelector('strong'), 'v-list-row__title');
      addCanonicalClass(copy.querySelector('small'), 'v-list-row__support');
    }
  });

  product.querySelectorAll('[data-ds-component="DS v2 / Info Row"],.ds24-info-row').forEach((el) => {
    addCanonicalClass(el, 'v-info-row');
    const children = directElementChildren(el);
    addCanonicalClass(children[0], 'v-info-row__label');
    addCanonicalClass(children[children.length - 1], 'v-info-row__value');
  });

  product.querySelectorAll('[data-ds-component="DS v2 / Key-value Row"],.ds24-key-value-row').forEach((el) => {
    addCanonicalClass(el, 'v-kv-row');
    const children = directElementChildren(el);
    addCanonicalClass(children[0], 'v-kv-row__key');
    addCanonicalClass(children[children.length - 1], 'v-kv-row__value');
    if (normalizeDsValue(el.dataset.dsPropState) === 'emphasis' || el.classList.contains('ds24-key-value-row--emphasis')) el.dataset.state = 'emphasis';
  });

  product.querySelectorAll('[data-ds-component="DS v2 / Summary Card"],.ds24-summary-card').forEach((el) => {
    addCanonicalClass(el, 'v-summary-card');
    addCanonicalClass(el.querySelector('.ds24-summary-card__title'), 'v-summary-card__title');
    addCanonicalClass(el.querySelector('.ds24-summary-card__body'), 'v-summary-card__body');
    const tone = normalizeDsValue(el.dataset.dsPropTone);
    if (tone && tone !== 'neutral') el.dataset.tone = tone;
  });

  product.querySelectorAll('[data-ds-component="DS v2 / Record Card"],.record-card').forEach((el) => addCanonicalClass(el, 'v-record-card'));

  product.querySelectorAll('[data-ds-component="VToast"],.toast').forEach((el) => {
    addCanonicalClass(el, 'v-toast');
    let tone = normalizeDsValue(el.dataset.dsPropType);
    if (!['success','warning','danger','info'].includes(tone)) tone = 'info';
    el.dataset.tone = tone;
    addCanonicalClass(el.querySelector('.toast-icon-box'), 'v-toast__icon');
    addCanonicalClass(el.querySelector('.toast-message,[data-ds-internal="VToast.message"]'), 'v-toast__message');
  });

  product.querySelectorAll('[data-ds-component="VBanner"],.v-banner').forEach((el) => {
    addCanonicalClass(el, 'v-banner');
    let tone = normalizeDsValue(el.dataset.dsPropTone);
    if (!tone) {
      if (el.className.includes('success')) tone = 'success';
      else if (el.className.includes('warning')) tone = 'warning';
      else if (el.className.includes('error') || el.className.includes('danger')) tone = 'danger';
      else tone = 'info';
    }
    el.dataset.tone = tone;
    el.dataset.density = normalizeDsValue(el.dataset.dsPropDensity) || 'default';
    const copy = el.querySelector('.v-banner-copy,[data-ds-internal="VBanner.copy"]');
    if (copy) {
      addCanonicalClass(copy, 'v-banner__copy');
      addCanonicalClass(copy.querySelector('strong'), 'v-banner__title');
      addCanonicalClass(copy.querySelector('span'), 'v-banner__message');
    }
  });

  product.querySelectorAll('[data-ds-component="VEmptyState"],.empty-state').forEach((el) => {
    addCanonicalClass(el, 'v-empty-state');
    addCanonicalClass(el.querySelector('[data-ds-component="VEmptyMedia"],.empty-state__icon,.empty-state-icon'), 'v-empty-state__icon');
    addCanonicalClass(el.querySelector('[data-ds-component="VEmptyTitle"],.empty-state__title,.empty-state h2,.empty-state h3'), 'v-empty-state__title');
    addCanonicalClass(el.querySelector('[data-ds-component="VEmptyDescription"],.empty-state__description,.empty-state p'), 'v-empty-state__description');
    addCanonicalClass(el.querySelector('.button,[data-ds-component="VButton"]'), 'v-empty-state__action');
  });

  product.querySelectorAll('[data-ds-component="VBottomSheet"],.bottom-sheet').forEach((el) => {
    addCanonicalClass(el, 'v-bottom-sheet');
    addCanonicalClass(el.querySelector('.bottom-sheet-handle,.sheet-handle,[data-ds-internal*="handle"]'), 'v-bottom-sheet__handle');
    addCanonicalClass(el.querySelector('.bottom-sheet-title,.sheet-title,h2,h3'), 'v-bottom-sheet__title');
    const content = el.querySelector('.bottom-sheet-content,.sheet-content');
    if (content) addCanonicalClass(content, 'v-bottom-sheet__content');
  });

  product.querySelectorAll('[data-ds-component="DS v2 / Sticky Footer"],.figma-sticky-footer,.sticky-footer').forEach((el) => {
    addCanonicalClass(el, 'v-sticky-footer');
    const buttons = directElementChildren(el).filter((child) => child.matches('button,[data-ds-component="VButton"]'));
    if (buttons.length >= 2) el.dataset.layout = 'dual';
  });

  product.querySelectorAll('[data-ds-component="DS v2 / Confirmation Sheet"],.confirm-dialog').forEach((el) => {
    addCanonicalClass(el, 'v-confirmation-sheet');
    addCanonicalClass(el.querySelector('h2,h3'), 'v-confirmation-sheet__title');
    addCanonicalClass(el.querySelector('p'), 'v-confirmation-sheet__description');
    addCanonicalClass(el.querySelector('.confirm-dialog-actions'), 'v-confirmation-sheet__actions');
  });
  product.querySelectorAll('[data-ds-component="DS v2 / Select Sheet"]').forEach((el) => addCanonicalClass(el, 'v-select-sheet'));
  product.querySelectorAll('[data-ds-component="DS v2 / Form Sheet"]').forEach((el) => addCanonicalClass(el, 'v-form-sheet'));
  product.querySelectorAll('[data-ds-component="DS v2 / Search Results Dropdown"]').forEach((el) => addCanonicalClass(el, 'v-search-results'));
  product.querySelectorAll('[data-ds-component="DS v2 / Search & Filter Header"]').forEach((el) => addCanonicalClass(el, 'v-search-filter-header'));
  product.querySelectorAll('[data-ds-component="DS v2 / Link"]').forEach((el) => addCanonicalClass(el, 'v-link'));

  product.querySelectorAll('[data-ds-component="VSearchBar"],.ds24-search,.search-box').forEach((el) => {
    addCanonicalClass(el, 'v-search');
    const input = el.querySelector('input');
    if (input) addCanonicalClass(input, 'v-control');
    const leading = directElementChildren(el).find((child) => child !== input && child.matches('svg,.v-icon,[data-icon]'));
    if (leading) addCanonicalClass(leading, 'v-search__leading');
  });

  const fieldSelector = [
    '[data-ds-component="VField"]', '[data-ds-component="VTextField"]', '[data-ds-component="VNumberField"]',
    '[data-ds-component="VMoneyField"]', '[data-ds-component="VSelect"]', '[data-ds-component="VDatePicker"]',
    '[data-ds-component="VDatePickerField"]', '[data-ds-component="VTextarea"]', '.form-field'
  ].join(',');
  product.querySelectorAll(fieldSelector).forEach((el) => {
    const isNativeControl = el.matches('input,select,textarea');
    const field = isNativeControl ? (el.closest('label,.form-field,.valuation-field') || el.parentElement) : el;
    if (field && field !== product) {
      addCanonicalClass(field, 'v-field');
      const rawState = normalizeDsValue(el.dataset.dsPropState || field.dataset.dsPropState);
      if (rawState) field.dataset.state = rawState;
      field.querySelectorAll('.input-shell,.select-shell,.date-shell,.money-shell').forEach((shell) => addCanonicalClass(shell, 'v-control-shell'));
      field.querySelectorAll('input,select,textarea').forEach((control) => addCanonicalClass(control, 'v-control'));
      field.querySelectorAll('.field-helper,.helper-text,.field-error,small').forEach((helper) => addCanonicalClass(helper, 'v-helper'));
    }
  });

  product.querySelectorAll('[data-ds-component="VCheckbox"],[data-ds-component="VRadio"]').forEach((el) => {
    const kind = el.dataset.dsComponent === 'VCheckbox' ? 'checkbox' : 'radio';
    const isRow = el.matches('label,button') || Boolean(el.querySelector('input,[role="radio"],[role="checkbox"]'));
    const stateValue = normalizeDsValue(el.dataset.dsPropState);
    const checked = el.matches(':checked') || el.getAttribute('aria-checked') === 'true' || el.getAttribute('aria-pressed') === 'true' || ['on','checked','selected'].includes(stateValue) || el.classList.contains('is-selected') || el.classList.contains('is-checked');
    const disabled = Boolean(el.disabled) || el.getAttribute('aria-disabled') === 'true' || stateValue === 'disabled';
    if (isRow) {
      addCanonicalClass(el, 'v-checkrow');
      el.dataset.kind = kind;
      el.dataset.state = disabled ? (checked ? 'disabled-on' : 'disabled-off') : (checked ? 'on' : 'off');
      const indicator = el.querySelector('.checkbox-control,.radio-control,.valuation-selection-control,.bj02-radio-control,.val14-radio-control,.v364-radio-control,[data-control]');
      if (indicator) addCanonicalClass(indicator, kind === 'checkbox' ? 'v-checkbox' : 'v-radio');
    } else {
      addCanonicalClass(el, kind === 'checkbox' ? 'v-checkbox' : 'v-radio');
      if (disabled) el.dataset.state = checked ? 'disabled-on' : 'disabled-off';
    }
  });

  product.querySelectorAll('[data-ds-component="VSegmentedControl"]').forEach((el) => {
    addCanonicalClass(el, 'v-segmented');
    directElementChildren(el).forEach((item) => {
      if (item.matches('button,[data-ds-component="VSegmentedControlItem"]')) {
        addCanonicalClass(item, 'v-segmented__item');
        const selected = item.getAttribute('aria-pressed') === 'true' || item.classList.contains('is-selected') || normalizeDsValue(item.dataset.dsPropSelected) === 'true';
        item.dataset.selected = selected ? 'true' : 'false';
      }
    });
  });

  product.querySelectorAll('[data-ds-component="DS v2 / Timeline Item"]').forEach((el) => {
    addCanonicalClass(el, 'v-timeline-item');
    addCanonicalClass(el.querySelector('.timeline-marker,.timeline-dot'), 'v-timeline-item__marker');
  });

  product.querySelectorAll('[data-ds-component="VNumericKeypadSheet"]').forEach((el) => {
    addCanonicalClass(el, 'v-numeric-keypad');
    addCanonicalClass(el.querySelector('.bj02-numeric-handle,.ds24-keypad__handle'), 'v-numeric-keypad__handle');
    addCanonicalClass(el.querySelector('.bj02-numeric-head,.ds24-keypad header'), 'v-numeric-keypad__header');
    addCanonicalClass(el.querySelector('.bj02-numeric-display,.ds24-keypad__value'), 'v-numeric-keypad__value');
    const grid = el.querySelector('.bj02-keypad-grid,.ds24-keypad__grid');
    if (grid) addCanonicalClass(grid, 'v-keypad-grid');
    el.querySelectorAll('.bj02-keypad-key,.ds24-keypad__grid button').forEach((key) => addCanonicalClass(key, 'v-keypad-key'));
  });

  product.querySelectorAll('[data-ds-component="VLoading"]').forEach((el) => {
    const spinner = el.matches('.generic-spinner,.v-loading-spinner') ? el : el.querySelector('.generic-spinner,.v-loading-spinner');
    if (spinner) { addCanonicalClass(spinner, 'v-loading'); spinner.dataset.size = spinner.dataset.size || '24'; }
  });
  product.querySelectorAll('[data-ds-component="VSkeleton"]').forEach((el) => {
    const skeletons = el.matches('.skeleton') ? [el] : [...el.querySelectorAll('.skeleton')];
    skeletons.forEach((item) => {
      addCanonicalClass(item, 'v-skeleton');
      if (item.classList.contains('skeleton--card')) item.dataset.type = 'card';
      else item.dataset.type = 'line';
    });
  });
  product.querySelectorAll('[data-ds-component="VFileDropZone"]').forEach((el) => {
    const dropzone = el.matches('.file-drop-zone,.review-card') ? el : (el.querySelector('.file-drop-zone,.io06-file-control') || el);
    addCanonicalClass(dropzone, 'v-dropzone');
    addCanonicalClass(dropzone.querySelector('strong'), 'v-dropzone__title');
    addCanonicalClass(dropzone.querySelector('small'), 'v-dropzone__support');
    if (el.matches('.form-field,label') && dropzone !== el) addCanonicalClass(el, 'v-field');
  });
  product.querySelectorAll('[data-ds-component="DS v2 / Audit Item"]').forEach((el) => addCanonicalClass(el, 'v-audit-item'));
  product.querySelectorAll('[data-ds-component="DS v2 / Metric Card"]').forEach((el) => addCanonicalClass(el, 'v-metric-card'));
}


function applyTheme7HtmlDsRuntimeMetadata() {
  const runtime = window.__VET45_PROTOTYPE__;
  if (!runtime) return;
  runtime.version = "5.0.2";
  runtime.htmlDesignSystem = {
    version: HTML_DS_VERSION,
    figmaAuthority: "2.0.3",
    entry: "../../../../../vet45-html-design-system/src/templates.css",
    repositoryPath: "specs/vet45-html-design-system",
    shared: true,
    adapter: "html-ds-alignment.css"
  };
  runtime.alignmentScope = "presentation-only";
}

function startTheme7HtmlDsAlignment() {
  const target = document.getElementById("app-screen");
  if (!target) return;
  alignHtmlDesignSystem(target);
  new MutationObserver(() => alignHtmlDesignSystem(target)).observe(target, { childList: true, subtree: true });
  applyTheme7HtmlDsRuntimeMetadata();
}

startTheme7HtmlDsAlignment();
