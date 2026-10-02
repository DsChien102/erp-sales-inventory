(() => {
  'use strict';

  const qsa = (root, selector) => Array.from(root.querySelectorAll(selector));
  const lower = (value) => String(value || '').toLowerCase();
  const add = (el, ...classes) => { if (el) el.classList.add(...classes.filter(Boolean)); return el; };

  function replaceTag(el, tagName, {interactive = false} = {}) {
    if (!el || el.tagName.toLowerCase() === tagName.toLowerCase()) return el;
    const next = document.createElement(tagName);
    for (const attr of Array.from(el.attributes)) {
      if (attr.name === 'type' && tagName !== 'button' && tagName !== 'input') continue;
      if (attr.name === 'disabled' && tagName !== 'button' && tagName !== 'input' && tagName !== 'select' && tagName !== 'textarea') continue;
      next.setAttribute(attr.name, attr.value);
    }
    while (el.firstChild) next.appendChild(el.firstChild);
    if (interactive) {
      next.setAttribute('role', next.getAttribute('role') || 'button');
      if (!next.hasAttribute('tabindex')) next.tabIndex = 0;
      if (el.disabled) next.setAttribute('aria-disabled', 'true');
    }
    el.replaceWith(next);
    return next;
  }

  function stateFrom(el) {
    const raw = lower(el?.dataset?.dsPropState || el?.dataset?.state);
    if (el?.disabled || el?.getAttribute?.('aria-disabled') === 'true' || raw.includes('disabled')) return 'disabled';
    if (raw.includes('selected') || el?.classList?.contains('is-selected') || el?.classList?.contains('is-active') || el?.getAttribute?.('aria-pressed') === 'true' || el?.getAttribute?.('aria-checked') === 'true') return 'selected';
    if (raw.includes('error')) return 'error';
    if (raw.includes('loading')) return 'loading';
    if (raw.includes('pressed')) return 'pressed';
    return raw && !raw.includes('.') ? raw : 'default';
  }

  function toneFrom(el, fallback = 'neutral') {
    const raw = lower(`${el?.dataset?.dsPropTone || ''} ${el?.dataset?.dsPropStatus || ''} ${el?.dataset?.tone || ''} ${el?.className || ''}`);
    if (raw.includes('danger') || raw.includes('error')) return 'danger';
    if (raw.includes('warning')) return 'warning';
    if (raw.includes('success')) return 'success';
    if (raw.includes('info')) return 'info';
    if (raw.includes('brand') || raw.includes('primary')) return 'brand';
    return fallback;
  }


  function normalizeShell(product) {
    if (!product || product.nodeType !== 1) return product;
    const hasLegacyShell = product.matches('.v-page-scaffold') || product.querySelector(':scope > .app-appbar,:scope > .app-content');
    add(product, 'v-template');
    product.dataset.htmlDsVersion = '1.6.0';
    product.dataset.rendererVersion = '5.4.0';

    const status = product.querySelector(':scope > .app-statusbar,:scope > .v-template__statusbar');
    if (status) add(status, 'v-template__statusbar');

    const appbar = product.querySelector(':scope > .app-appbar,:scope > .v-appbar');
    if (appbar) {
      add(appbar, 'v-appbar');
      const back = appbar.querySelector('.app-back-button,.v-appbar__leading');
      if (back) {
        add(back, 'v-appbar__leading');
        if (back.matches('button,[role="button"]') || back.querySelector('[data-v-icon],svg')) add(back, 'v-icon-btn');
        else back.classList.remove('v-icon-btn');
      }
      let copy = appbar.querySelector('.app-appbar-copy,.v-appbar__copy');
      if (!copy) {
        copy = document.createElement('div'); copy.className = 'v-appbar__copy app-appbar-copy';
        Array.from(appbar.children).filter((child) => child !== back && !child.classList.contains('v-appbar__trailing')).forEach((child) => copy.appendChild(child));
        if (back && back.nextSibling) appbar.insertBefore(copy, back.nextSibling); else appbar.appendChild(copy);
      }
      add(copy, 'v-appbar__copy', 'app-appbar-copy');
      const title = copy.querySelector('.v-appbar__title,h1,h2,h3,h4');
      if (title) add(title, 'v-appbar__title');
      const subtitle = copy.querySelector('.v-appbar__subtitle,p,small');
      if (subtitle && subtitle !== title) add(subtitle, 'v-appbar__subtitle');
      if (!appbar.querySelector(':scope > .v-appbar__trailing')) {
        const trailing = document.createElement('div'); trailing.className = 'v-appbar__trailing'; trailing.setAttribute('aria-hidden','true'); appbar.appendChild(trailing);
      }
      appbar.dataset.type = back ? 'back' : 'root';
    }

    const content = product.querySelector(':scope > .app-content,:scope > .v-template__scroll');
    const footer = product.querySelector(':scope > .app-actions,:scope > .v-sticky-footer');
    const bottomNav = product.querySelector(':scope > .v-bottom-nav');
    if (content) {
      add(content, 'v-template__scroll', 'app-content');
      content.dataset.withAppbar = String(Boolean(appbar));
      if (footer) content.dataset.withFooter = 'true'; else delete content.dataset.withFooter;
      if (bottomNav) content.dataset.withBottomNav = 'true'; else delete content.dataset.withBottomNav;
      let page = content.querySelector(':scope > .body-stack,:scope > .v-page');
      if (!page) {
        page = document.createElement('div'); page.className = 'v-page v-stack-2 body-stack';
        while (content.firstChild) page.appendChild(content.firstChild);
        content.appendChild(page);
      }
      add(page, 'v-page', 'v-stack-2', 'body-stack');
    }

    if (footer) add(footer, 'v-sticky-footer', 'app-actions');
    if (!product.dataset.template || hasLegacyShell) {
      product.dataset.template = bottomNav ? 'root-list' : footer ? 'detail' : appbar?.dataset.type === 'back' ? 'nested-list' : 'root-list';
    }
    return product;
  }

  function normalizeButtons(root) {
    qsa(root, '[data-ds-component="VButton"],button.button,button.ds24-button').forEach((el) => {
      add(el, 'v-btn');
      const raw = lower(`${el.dataset.dsPropVariant || ''} ${el.dataset.dsPropHierarchy || ''} ${el.className}`);
      const danger = toneFrom(el) === 'danger' || lower(el.dataset.dsPropTone).includes('danger');
      let hierarchy = 'primary';
      if (danger) hierarchy = 'danger';
      else if (raw.includes('secondary')) hierarchy = 'secondary';
      else if (raw.includes('tertiary') || raw.includes('link') || raw.includes('inline-edit')) hierarchy = 'tertiary';
      el.dataset.hierarchy = hierarchy;
      el.dataset.size = raw.includes('small') ? 'small' : (el.dataset.size || 'default');
      if (raw.includes('full') || el.dataset.dsPropWidth === 'fill') el.dataset.width = 'fill';
      if (el.disabled) el.dataset.state = 'disabled';
    });
    qsa(root, '.v-sticky-footer .v-btn[data-width="fill"],.v-sticky-footer[data-layout="single"] .v-btn').forEach((el) => { el.style.width = '100%'; });
  }

  function normalizeIcons(root) {
    const aliases = {
      'VIcons.arrowLeft':'chevron-left','VIcons.chevronLeft':'chevron-left','VIcons.arrowRight':'chevron-right','VIcons.chevronRight':'chevron-right','VIcons.arrowDropDown':'chevron-down',
      'VIcons.description':'file-text','li:cloud-upload':'cloud-upload','VIcons.bolt':'zap','VIcons.info':'info','VIcons.warning':'triangle-alert','VIcons.search':'search','VIcons.tune':'sliders-horizontal',
      'VIcons.warehouse':'warehouse','VIcons.calendar':'calendar','VIcons.save':'check','VIcons.inventory':'package','VIcons.check':'check','VIcons.success':'circle-check','VIcons.error':'circle-x',
      'VIcons.close':'x','VIcons.shield':'shield-check','VIcons.person':'user','VIcons.clock':'clock','VIcons.refresh':'refresh-cw','VIcons.lock':'lock','VIcons.inbox':'inbox','VIcons.checkList':'logs','VIcons.moreHoriz':'ellipsis','VIcons.history':'history','VIcons.edit':'pencil'
    };
    qsa(root, 'svg[data-ds-component="VIcon"]').forEach((svg) => {
      const span = document.createElement('span');
      const semantic = svg.dataset.dsIcon || '';
      span.dataset.vIcon = aliases[semantic] || semantic.replace(/^VIcons\./, '').replace(/[A-Z]/g, (m) => '-' + m.toLowerCase()).replace(/^-/, '') || 'info';
      span.dataset.size = svg.classList.contains('icon--empty-media') ? '32' : svg.classList.contains('icon--24') ? '24' : '20';
      span.setAttribute('aria-hidden', 'true');
      svg.replaceWith(span);
    });
  }

  function normalizeTypography(root) {
    qsa(root, '[data-ds-component="VText"]').forEach((el) => {
      const variant = lower(`${el.dataset.dsPropVariant || ''} ${el.dataset.dsPropStyle || ''}`);
      if (/caption/.test(variant)) add(el, 'v-caption');
      else if (/bodysmall|body\/small/.test(variant)) add(el, 'v-body-sm');
      else if (/label/.test(variant)) add(el, 'v-label');
      else add(el, 'v-body');
    });
    qsa(root, '.vet45-text-style-4').forEach((el) => add(el, 'v-h3'));
    qsa(root, '.vet45-text-style-5').forEach((el) => add(el, 'v-h4'));
    qsa(root, '.vet45-text-style-6,.vet45-text-style-7').forEach((el) => add(el, 'v-body-sm'));
    qsa(root, '.vet45-text-style-11').forEach((el) => add(el, 'v-caption'));
  }

  function normalizeSearch(root) {
    const candidates = qsa(root, '[data-ds-component="VSearchBar"],.ds24-search,.search-box,.search-field').filter((el) => el.querySelector('input'));
    candidates.forEach((el) => {
      add(el, 'v-search');
      el.dataset.state = stateFrom(el);
      const input = el.querySelector('input');
      add(input, 'v-control');
      if (!el.querySelector(':scope > .v-search__leading')) {
        const leading = document.createElement('span');
        leading.className = 'v-search__leading';
        leading.innerHTML = '<span data-v-icon="search" data-size="20"></span>';
        el.insertBefore(leading, el.firstChild);
      }
      const oldLeading = el.querySelector('.search-icon,.ds24-search__icon');
      if (oldLeading && !oldLeading.classList.contains('v-search__leading')) oldLeading.remove();
    });
  }

  function fieldKind(el) {
    const name = el.dataset.dsComponent || '';
    if (/Textarea/.test(name) || el.querySelector('textarea')) return 'textarea';
    if (/Money/.test(name)) return 'money';
    if (/Select/.test(name) || el.querySelector('select')) return 'select';
    if (/Date/.test(name) || el.querySelector('input[type="date"]')) return 'date';
    if (/Number/.test(name) || el.querySelector('input[type="number"]')) return 'number';
    return 'text';
  }

  function normalizeFields(root) {
    const wrappers = new Set();
    qsa(root, '[data-ds-component="VTextField"],[data-ds-component="VNumberField"],[data-ds-component="VMoneyField"],[data-ds-component="VDatePicker"],[data-ds-component="VDatePickerField"],[data-ds-component="VDateField"],[data-ds-component="VSelect"],[data-ds-component="VTextarea"],.form-field,.ac310-field,.val13-select-field,.val14-field').forEach((el) => {
      const wrapper = el.matches('input,textarea,select') ? (el.closest('label,.form-field,.ac310-field') || el.parentElement) : el;
      if (wrapper) wrappers.add(wrapper);
    });
    qsa(root, 'select[data-ds-component="VSelect"],input[data-ds-component="VDatePicker"],input[data-ds-component="VNumberField"]').forEach((control) => {
      const wrapper = control.closest('label,.form-field,.ac310-field') || control.parentElement;
      if (wrapper) wrappers.add(wrapper);
    });

    wrappers.forEach((el) => {
      let control = el.matches('input,textarea,select') ? el : el.querySelector('input,textarea,select');
      const selectTrigger = !control ? el.querySelector('[data-bj02-open-supplier-sheet],.bj02-vselect-trigger') : null;
      if (!control && selectTrigger) {
        add(el, 'v-field', 'v-select-field'); el.dataset.kind='select'; el.dataset.state=selectTrigger.disabled?'disabled':'filled';
        let label=el.querySelector(':scope > label'); if(label)add(label,'v-field__label');
        const shell=document.createElement('div'); shell.className='v-select-shell'; shell.setAttribute('role','button'); shell.tabIndex=selectTrigger.disabled?-1:0;
        for (const attr of Array.from(selectTrigger.attributes)) if (attr.name.startsWith('data-') || attr.name.startsWith('aria-')) shell.setAttribute(attr.name,attr.value);
        if(selectTrigger.disabled)shell.setAttribute('aria-disabled','true');
        const value=document.createElement('span'); value.className='v-select-shell__value'; value.textContent=selectTrigger.querySelector('span')?.textContent?.trim() || selectTrigger.textContent.trim();
        const icon=document.createElement('span'); icon.dataset.vIcon='chevron-down'; icon.dataset.tone='secondary'; shell.append(value,icon); selectTrigger.replaceWith(shell); return;
      }
      if (!control) return;
      const component = `${el.dataset.dsComponent || ''} ${control.dataset.dsComponent || ''}`;
      const kind = /Select/.test(component) || control.tagName === 'SELECT' ? 'select'
        : /Date/.test(component) ? 'date'
        : /Money/.test(component) ? 'money'
        : /Number/.test(component) || control.type === 'number' ? 'number'
        : control.tagName === 'TEXTAREA' ? 'textarea' : 'text';
      add(el, 'v-field');
      if (kind === 'select') add(el, 'v-select-field');
      if (kind === 'date') add(el, 'v-date-field');
      if (kind === 'number') add(el, 'v-number-field');
      if (kind === 'money') add(el, 'v-money-field');
      el.dataset.kind = kind;
      el.dataset.state = control.disabled ? 'disabled' : (control.value ? 'filled' : stateFrom(el));

      let label = el.querySelector(':scope > label,.field-label,.io06-field__label');
      if (!label && el.tagName === 'LABEL') label = Array.from(el.children).find((x) => x.tagName === 'SPAN' && !x.classList.contains('v-helper')) || null;
      if (!label) {
        const text = el.dataset.dsPropLabel || control.getAttribute('aria-label') || '';
        if (text) { label = document.createElement('label'); label.textContent = text; el.insertBefore(label, el.firstChild); }
      }
      if (label) add(label, 'v-field__label');

      const helper = el.querySelector('.field-helper,.helper-text,.v-helper,.v-field__helper,:scope > small:last-child');
      if (helper) add(helper, 'v-helper');

      if (kind === 'select') {
        let shell = el.querySelector(':scope > .v-select-shell');
        if (!shell) {
          shell = document.createElement('div'); shell.className = 'v-select-shell';
          shell.style.position = 'relative';
          const value = document.createElement('span'); value.className = 'v-select-shell__value';
          value.textContent = control.options?.[control.selectedIndex]?.textContent?.trim() || control.value || 'Chọn giá trị';
          const icon = document.createElement('span'); icon.dataset.vIcon = 'chevron-down'; icon.dataset.tone = 'secondary';
          shell.append(value, icon);
          const oldShell = control.closest('.bj02-native-select-shell,.input-shell');
          if (oldShell && oldShell.parentElement === el) oldShell.replaceWith(shell); else control.parentElement === el ? el.insertBefore(shell, control) : el.appendChild(shell);
          shell.appendChild(control);
        }
        const value = shell.querySelector('.v-select-shell__value');
        control.classList.remove('v-control');
        Object.assign(control.style,{position:'absolute',inset:'0',width:'100%',height:'100%',opacity:'0',cursor:'pointer'});
        const sync=()=>{ if(value) value.textContent=control.options?.[control.selectedIndex]?.textContent?.trim() || control.value || 'Chọn giá trị'; el.dataset.state=control.value?'filled':'default'; };
        control.addEventListener('change',sync); sync();
      } else if (kind === 'date') {
        let shell = el.querySelector(':scope > .v-date-shell');
        if (!shell) {
          shell = document.createElement('div'); shell.className = 'v-date-shell';
          const icon = document.createElement('span'); icon.dataset.vIcon = 'calendar'; icon.dataset.tone = 'secondary';
          const oldShell = control.closest('.bj02-date-shell,.input-shell');
          if (oldShell && oldShell.parentElement === el) oldShell.replaceWith(shell); else control.parentElement === el ? el.insertBefore(shell, control) : el.appendChild(shell);
          shell.append(icon, control);
        }
        add(control,'v-date-shell__value'); control.classList.remove('v-control');
        Object.assign(control.style,{border:'0',outline:'0',background:'transparent',padding:'0',minWidth:'0',width:'100%'});
      } else if (kind === 'money') {
        let shell = el.querySelector(':scope > .v-money-shell');
        if (!shell) { shell=document.createElement('div'); shell.className='v-money-shell'; control.parentElement===el?el.insertBefore(shell,control):el.appendChild(shell); shell.appendChild(control); }
        control.classList.remove('v-control'); Object.assign(control.style,{border:'0',outline:'0',background:'transparent',padding:'0',minWidth:'0',width:'100%'});
        if (!shell.querySelector('.v-money-shell__currency')) { const c=document.createElement('span'); c.className='v-money-shell__currency'; c.textContent='₫'; shell.appendChild(c); }
      } else {
        const oldShell = control.closest('.input-shell,.quantity-control');
        if (oldShell && oldShell !== el && oldShell.parentElement === el) oldShell.replaceWith(control);
        add(control, 'v-control');
      }
    });

    qsa(root, '[data-ds-component="VFileDropZone"],.file-drop-zone,.io06-file-field').forEach((outer) => {
      const zone = outer.matches('.file-drop-zone') ? outer : (outer.querySelector('.file-drop-zone') || outer);
      add(zone, 'v-dropzone');
      zone.dataset.state = stateFrom(zone);
      const input = zone.querySelector('input[type="file"]');
      if (input) Object.assign(input.style,{position:'absolute',width:'1px',height:'1px',opacity:'0',pointerEvents:'none'});
      const title = zone.querySelector('strong,.file-drop-copy strong');
      const support = zone.querySelector('small,.file-drop-copy span');
      if (title) add(title, 'v-dropzone__title');
      if (support) add(support, 'v-dropzone__support');
    });
  }

  function normalizeSelection(root) {
    qsa(root, '[data-ds-component="VSegmentedControl"],.cf-segmented').forEach((group) => {
      add(group, 'v-segmented');
      Array.from(group.children).forEach((item) => {
        if (!item.matches('button,[data-ds-component="VSegmentedControlItem"]')) return;
        add(item, 'v-segmented__item');
        item.dataset.selected = String(item.classList.contains('is-selected') || item.dataset.dsPropSelected === 'true' || item.getAttribute('aria-pressed') === 'true');
      });
    });
    qsa(root, '[data-ds-component="VChip"],.filter-chip').forEach((el) => {
      add(el, 'v-chip');
      const selected = el.dataset.dsPropSelected === 'true' || el.classList.contains('is-active') || el.classList.contains('is-selected');
      if (selected) el.dataset.tone = 'brand';
      if (el.disabled) el.dataset.state = 'disabled';
    });
    qsa(root, '[data-ds-component="VBadge"],.status-badge').forEach((el) => { add(el, 'v-badge'); el.dataset.tone = toneFrom(el, 'neutral'); });
    qsa(root, '[data-ds-component="VRadio"],[data-ds-component="VCheckbox"]').forEach((row) => {
      const input = row.querySelector('input[type="radio"],input[type="checkbox"]');
      const kind = input?.type === 'checkbox' || row.dataset.dsComponent === 'VCheckbox' ? 'checkbox' : 'radio';
      add(row, 'v-checkrow');
      row.classList.remove('v-radio','v-checkbox');
      row.dataset.kind = kind;
      const checked = Boolean(input?.checked);
      const disabled = Boolean(input?.disabled);
      row.dataset.state = disabled ? (checked ? 'disabled-on' : 'disabled-off') : (checked ? 'on' : 'off');
      if (input) {
        input.style.position = 'absolute'; input.style.width = '1px'; input.style.height = '1px'; input.style.padding = '0'; input.style.margin = '-1px'; input.style.overflow = 'hidden'; input.style.clip = 'rect(0,0,0,0)'; input.style.whiteSpace = 'nowrap'; input.style.border = '0';
      }
      let control = row.querySelector(kind === 'radio' ? '.v-radio,.v364-radio-control,.ac310-radio-control' : '.v-checkbox,.v364-checkbox-control,.ac310-checkbox-control');
      if (!control) { control = document.createElement('span'); if (input) input.insertAdjacentElement('afterend', control); else row.insertBefore(control,row.firstChild); }
      add(control, kind === 'radio' ? 'v-radio' : 'v-checkbox');
      const copy = row.querySelector('.v364-radio-copy,.ac310-radio-copy,.cr-choice>span,.v-checkrow__copy');
      if (copy) add(copy, 'v-grow');
    });
  }

  function normalizeListRows(root) {
    let rows = qsa(root, '[data-ds-component="DS v2 / List Row"]');
    rows.forEach((original) => {
      let row = original;
      if (row.tagName === 'BUTTON') row = replaceTag(row, 'div', {interactive:true});
      add(row, 'v-list-row');
      const density = lower(row.dataset.dsPropDensity || row.dataset.density);
      row.dataset.density = density.includes('compact') ? 'compact' : 'default';
      const type = lower(row.dataset.dsPropType || row.dataset.type);
      row.dataset.type = type.includes('selection') ? 'selection' : type.includes('status') ? 'status' : 'navigation';
      row.dataset.state = stateFrom(row);
      if ((row.dataset.type === 'navigation' || row.hasAttribute('data-bj01-product') || row.hasAttribute('data-bj02-document')) && !row.hasAttribute('role')) {
        row.setAttribute('role','button'); row.tabIndex = 0;
      }
      let copy = row.querySelector('.v-list-row__copy,.v-list-row__content,.ds24-list-row__copy,.quick-uom-choice-copy,.io-product-copy');
      if (copy) { add(copy, 'v-list-row__copy'); }
      else {
        const textNodes = Array.from(row.children).filter((child) => !child.matches('[data-v-icon],.v-badge,.v-radio,.v-checkbox,.ds24-list-row__trailing'));
        if (textNodes.length) {
          copy = document.createElement('div'); copy.className = 'v-list-row__copy';
          const first = textNodes[0];
          if (first.tagName === 'DIV' && first.children.length) {
            while (first.firstChild) copy.appendChild(first.firstChild);
            first.remove();
          } else {
            textNodes.forEach((node) => copy.appendChild(node));
          }
          const trailing = row.querySelector('.ds24-list-row__trailing,[data-v-icon="chevron-right"],.v-badge,.v-radio');
          row.insertBefore(copy, trailing || null);
        }
      }
      if (copy) {
        let title = copy.querySelector('.v-list-row__title');
        if (!title) title = copy.querySelector('strong,h3,h4,.ds24-list-row__title');
        if (title) add(title, 'v-list-row__title');
        let support = copy.querySelector('.v-list-row__support');
        if (!support) support = copy.querySelector('small,p,.ds24-list-row__support');
        if (support && support !== title) add(support, 'v-list-row__support');
      }
      const trailing = row.querySelector('.ds24-list-row__trailing');
      if (trailing) add(trailing, 'v-row-2');
      if (row.dataset.type === 'navigation' && !row.querySelector('[data-v-icon="chevron-right"]')) {
        const chevron = document.createElement('span'); chevron.dataset.vIcon = 'chevron-right'; chevron.dataset.size = '20'; chevron.dataset.tone = 'secondary'; row.appendChild(chevron);
      }
    });
  }


  function normalizeRecordCards(root) {
    qsa(root, '[data-ds-component="DS v2 / Record Card"],.v-record-card').forEach((original) => {
      let card = original;
      if (card.tagName === 'BUTTON') card = replaceTag(card, 'div', {interactive:true});
      add(card, 'v-record-card');
      card.dataset.status = lower(card.dataset.dsPropStatus).includes('hidden') ? 'hidden' : (card.dataset.status || 'hidden');
      const status = card.querySelector('.v-badge,.status-badge'); if (status) add(status,'v-record-card__status');
    });
  }

  function normalizeLinks(root) {
    qsa(root, '[data-ds-component="DS v2 / Link"],.v430-link').forEach((el) => add(el, 'v-link'));
  }

  function normalizeCollapsibles(root) {
    qsa(root, '.lot-accordion-item').forEach((item) => {
      add(item, 'v-collapsible');
      const expanded = item.classList.contains('is-expanded') || item.querySelector('[aria-expanded="true"]');
      item.dataset.state = expanded ? 'expanded' : 'collapsed';
      const wrapper = item.querySelector(':scope > .lot-accordion-header');
      const button = wrapper?.querySelector(':scope > .lot-accordion-toggle') || item.querySelector(':scope > .lot-accordion-toggle');
      let header = button;
      if (button) {
        header = replaceTag(button, 'div', {interactive:true});
        add(header, 'v-collapsible__header');
        const copy = header.querySelector('.lot-accordion-copy'); if (copy) add(copy,'v-grow');
        const chevron = header.querySelector('.lot-accordion-chevron'); if (chevron) add(chevron,'v-collapsible__chevron');
        if (wrapper && wrapper !== header) wrapper.replaceWith(header);
      }
      const bodyChildren = Array.from(item.children).filter((child) => child !== header && !child.classList.contains('v-collapsible__body'));
      if (bodyChildren.length) {
        let body = item.querySelector(':scope > .v-collapsible__body');
        if (!body) { body = document.createElement('div'); body.className = 'v-collapsible__body'; item.appendChild(body); }
        bodyChildren.forEach((child) => body.appendChild(child));
      }
    });
  }

  function normalizeQuantityControls(root) {
    qsa(root, '.bj02-quantity-input-stack').forEach((stack)=>add(stack,'v-quantity-grid'));
    qsa(root, '.bj02-quantity-input-row').forEach((row) => {
      const trigger = row.querySelector('.bj02-quantity-input-trigger');
      if (!trigger) return;
      const labelText = row.querySelector('.bj02-quantity-input-label')?.textContent?.trim() || 'Số lượng';
      const value = trigger.querySelector('.bj02-quantity-input-value')?.textContent?.trim() || '0';
      const unit = trigger.querySelector('.bj02-quantity-input-unit')?.textContent?.trim() || '';
      const field = document.createElement('div'); field.className='v-field v-number-field'; field.dataset.kind='number';
      field.dataset.state = trigger.disabled ? 'disabled' : 'filled';
      const label=document.createElement('label'); label.className='v-field__label'; label.textContent=labelText;
      const input=document.createElement('input'); input.className='v-control'; input.type='text'; input.inputMode='numeric'; input.readOnly=true; input.value=value;
      for (const attr of Array.from(trigger.attributes)) if (attr.name.startsWith('data-') || attr.name==='aria-label') input.setAttribute(attr.name,attr.value);
      if (trigger.disabled) input.disabled=true;
      const helper=document.createElement('span'); helper.className='v-helper'; helper.textContent=unit ? `Đơn vị: ${unit}` : 'Nhập số lượng';
      field.append(label,input,helper); row.replaceWith(field);
    });
    qsa(root, '.ds24-field').forEach((field) => {
      const trigger = field.querySelector('.ds24-quantity-trigger'); if (!trigger) return;
      add(field,'v-field','v-number-field'); field.dataset.kind='number'; field.dataset.state=trigger.disabled?'disabled':'filled';
      const label = field.querySelector(':scope > span:first-child'); if(label) add(label,'v-field__label');
      const value=trigger.querySelector('span')?.textContent?.trim() || '0'; const unit=trigger.querySelector('small')?.textContent?.trim() || '';
      const input=document.createElement('input'); input.className='v-control'; input.type='text'; input.inputMode='numeric'; input.readOnly=true; input.value=value;
      for (const attr of Array.from(trigger.attributes)) if (attr.name.startsWith('data-') || attr.name==='aria-label') input.setAttribute(attr.name,attr.value);
      if(trigger.disabled)input.disabled=true; trigger.replaceWith(input);
      if(unit){ const helper=document.createElement('span');helper.className='v-helper';helper.textContent=`Đơn vị: ${unit}`;field.appendChild(helper); }
    });
    qsa(root, '.quantity-field').forEach((field)=>{
      add(field,'v-field','v-number-field'); field.dataset.kind='number';
      const label=field.querySelector('.quantity-label'); if(label)add(label,'v-field__label');
      const input=field.querySelector('input'); if(input){const shell=input.closest('.quantity-control');if(shell&&shell.parentElement===field)shell.replaceWith(input);add(input,'v-control');}
    });
  }

  function normalizeCards(root) {
    qsa(root, '[data-ds-component="VCard"],.v-card').forEach((original) => {
      let card = original;
      if (card.tagName === 'BUTTON') card = replaceTag(card, 'div', {interactive:true});
      add(card, 'v-card');
      if (card.children.length && !card.querySelector(':scope > .v-card__body,:scope > .v-card-header,:scope > .v-card-content,:scope > .v-card-footer') && !card.classList.contains('v-summary-card') && !card.classList.contains('v-metric-card')) {
        const body = document.createElement('div'); body.className = 'v-card__body';
        while (card.firstChild) body.appendChild(card.firstChild);
        card.appendChild(body);
      }
    });
  }

  function normalizeInfoRows(root) {
    qsa(root, '[data-ds-component="DS v2 / Info Row"],.v-info-row').forEach((el) => {
      add(el, 'v-info-row');
      const children = Array.from(el.children);
      const label = el.querySelector('.v-info-row__label') || children[0];
      const value = el.querySelector('.v-info-row__value') || children[1];
      if (label) add(label, 'v-info-row__label'); if (value) add(value, 'v-info-row__value');
    });
    qsa(root, '[data-ds-component="DS v2 / Key-value Row"],.v-kv-row').forEach((el) => {
      add(el, 'v-kv-row');
      const children = Array.from(el.children);
      const key = el.querySelector('.v-kv-row__key') || children[0];
      const value = el.querySelector('.v-kv-row__value') || children[1];
      if (key) add(key, 'v-kv-row__key'); if (value) add(value, 'v-kv-row__value');
      if (lower(el.dataset.dsPropEmphasis).includes('true')) el.dataset.state = 'emphasis';
    });
  }

  function normalizeFeedback(root) {
    qsa(root, '[data-ds-component="VBanner"],.v-banner').forEach((el) => {
      add(el, 'v-banner'); el.dataset.tone = toneFrom(el, 'info');
      if (!el.dataset.density) el.dataset.density = lower(el.dataset.dsPropDensity).includes('compact') ? 'compact' : 'default';
      let copy = el.querySelector('.v-banner__copy,.v-banner-copy');
      if (!copy) {
        copy = document.createElement('div'); copy.className = 'v-banner__copy';
        Array.from(el.children).filter((child) => !child.matches('[data-v-icon]')).forEach((child) => copy.appendChild(child));
        el.appendChild(copy);
      }
      add(copy, 'v-banner__copy');
      const title = copy.querySelector('.v-banner__title,strong,h3,h4'); if (title) add(title, 'v-banner__title');
      const msg = copy.querySelector('.v-banner__message,p,span:not(.v-banner__title)'); if (msg && msg !== title) add(msg, 'v-banner__message');
    });
    qsa(root, '[data-ds-component="VEmptyState"],.empty-state,.ds24-empty').forEach((el) => {
      add(el, 'v-empty-state');
      const media = el.querySelector('[data-ds-component="VEmptyMedia"],.icon-box,.ds24-empty__media');
      const title = el.querySelector('[data-ds-component="VEmptyTitle"],h3,.ds24-empty__title');
      const desc = el.querySelector('[data-ds-component="VEmptyDescription"],p,.ds24-empty__description');
      if (media) add(media, 'v-empty-state__icon'); if (title) add(title, 'v-empty-state__title'); if (desc) add(desc, 'v-empty-state__description');
    });
    qsa(root, '[data-ds-component="VLoading"]').forEach((el) => {
      const hasContent = Boolean(el.querySelector('strong,p,span:not(.v-loading-spinner)') || (el.textContent || '').trim());
      if (!hasContent && !el.querySelector('.v-loading-spinner')) {
        add(el, 'v-loading');
        el.dataset.size = el.dataset.size || '24';
        return;
      }
      add(el, 'v-card', 'v-stack-2');
      const spinner = el.querySelector('.v-loading-spinner');
      if (spinner) { add(spinner, 'v-loading'); spinner.dataset.size = spinner.dataset.size || '24'; }
      const title = el.querySelector('strong');
      const desc = el.querySelector('p');
      if (title) add(title, 'v-label');
      if (desc) add(desc, 'v-body-sm', 'v-muted');
    });
    qsa(root, '.v-loading-spinner').forEach((el) => { add(el, 'v-loading'); el.dataset.size = el.dataset.size || '24'; });
    qsa(root, '[data-ds-component="VSkeleton"] .skeleton').forEach((el) => add(el, 'v-skeleton'));
  }

  function normalizeFooters(root) {
    qsa(root, '[data-ds-component="DS v2 / Sticky Footer"],.app-actions').forEach((footer) => {
      add(footer, 'v-sticky-footer');
      const buttons = qsa(footer, ':scope > button');
      footer.dataset.layout = buttons.length > 1 ? 'dual' : 'single';
      buttons.forEach((btn) => { add(btn, 'v-btn'); if (buttons.length === 1) btn.dataset.width = 'fill'; });
    });
  }

  function normalizeOverlays(root) {
    qsa(root, '.sheet-backdrop,.confirm-backdrop,.bottom-sheet-backdrop,.bj02-numeric-backdrop,.ds24-overlay').forEach((el) => { add(el, 'v-overlay'); el.dataset.placement = 'bottom'; });
    qsa(root, '[data-ds-component="VNumericKeypadSheet"],.bj02-numeric-sheet,.ds24-keypad').forEach((sheet)=>{
      add(sheet,'v-numeric-keypad');
      let handle=sheet.querySelector('.bj02-numeric-handle,.ds24-keypad__handle,.v-numeric-keypad__handle');
      if(handle){ const area=document.createElement('div');area.className='v-numeric-keypad__handle-area';add(handle,'v-numeric-keypad__handle');handle.parentElement?.insertBefore(area,handle);area.appendChild(handle); }
      const head=sheet.querySelector('.bj02-numeric-head,header'); if(head)add(head,'v-numeric-keypad__header');
      const value=sheet.querySelector('.bj02-numeric-display,.ds24-keypad__value'); if(value)add(value,'v-numeric-keypad__value');
      let grid=sheet.querySelector('.bj02-keypad-grid,.ds24-keypad__grid'); if(grid){add(grid,'v-keypad-grid'); qsa(grid,'.bj02-keypad-row').forEach(r=>{while(r.firstChild)grid.insertBefore(r.firstChild,r);r.remove();}); qsa(grid,'.bj02-keypad-key,button').forEach(k=>add(k,'v-keypad-key'));}
      const actions=sheet.querySelector('.bj02-numeric-actions,.ds24-keypad__actions'); if(actions){add(actions,'v-numeric-keypad__actions');qsa(actions,'button').forEach(b=>add(b,'v-btn'));}
    });
    qsa(root, '[data-ds-component="VBottomSheet"],.bottom-sheet,.ds24-sheet').forEach((sheet) => {
      add(sheet, 'v-bottom-sheet');
      const handle = sheet.querySelector('.sheet-handle,.bottom-sheet-handle,.ds24-sheet__handle,.bj02-review-sheet-handle');
      const title = sheet.querySelector('.sheet-title h3,.bottom-sheet-title,.ds24-sheet>h3,.v-bottom-sheet__title');
      const content = sheet.querySelector('.sheet-content,.bottom-sheet-content,.ds24-sheet__body,.v-bottom-sheet__content');
      if (handle) add(handle, 'v-bottom-sheet__handle'); if (title) add(title, 'v-bottom-sheet__title'); if (content) add(content, 'v-bottom-sheet__content');
    });
    qsa(root, '[data-ds-component="DS v2 / Confirmation Sheet"],.confirm-dialog').forEach((sheet) => {
      add(sheet, 'v-confirmation-sheet');
      const title = sheet.querySelector('h2,h3,.v-confirmation-sheet__title'); const desc = sheet.querySelector('p,.v-confirmation-sheet__description'); const actions = sheet.querySelector('.confirm-dialog-actions,.v-confirmation-sheet__actions');
      if (title) add(title, 'v-confirmation-sheet__title'); if (desc) add(desc, 'v-confirmation-sheet__description'); if (actions) add(actions, 'v-confirmation-sheet__actions');
      sheet.dataset.tone = sheet.dataset.dsPropIsDestructive === 'true' ? 'danger' : (sheet.dataset.tone || 'default');
    });
    qsa(root, '[data-ds-component="DS v2 / Select Sheet"],.ds24-select-sheet').forEach((sheet) => {
      add(sheet, 'v-select-sheet'); const handle = sheet.querySelector('.ds24-sheet__handle,.v-sheet-handle'); if (handle) add(handle, 'v-sheet-handle'); const title = sheet.querySelector('h3,.v-select-sheet__title'); if (title) add(title, 'v-select-sheet__title'); const results = sheet.querySelector('.ds24-list-stack,.v-select-sheet__results'); if (results) add(results, 'v-select-sheet__results');
    });
  }

  function normalizeTimelineAudit(root) {
    qsa(root, '.generic-timeline .timeline-event').forEach((item) => {
      add(item, 'v-timeline-item');
      const marker = item.querySelector('.timeline-dot,.timeline-marker');
      if (marker) add(marker, 'v-timeline-item__marker');
      const copy = item.querySelector('.timeline-copy');
      if (copy) {
        add(copy, 'v-grow', 'v-stack-2');
        const title = copy.querySelector('strong');
        const desc = copy.querySelector('span:not(.v-badge):not([data-v-icon])');
        if (title) add(title, 'v-label');
        if (desc) add(desc, 'v-body-sm');
        const badge = copy.querySelector('.v-badge,[data-ds-component="VBadge"]');
        if (badge) { add(badge, 'v-shrink-0'); item.appendChild(badge); }
      }
    });
    qsa(root, '.as-of').forEach((row) => {
      add(row, 'v-info-row');
      const label = row.querySelector('span');
      const value = row.querySelector('strong');
      if (label) add(label, 'v-info-row__label');
      if (value) add(value, 'v-info-row__value');
    });
    qsa(root, '[data-ds-component="DS v2 / Timeline Item"],.timeline-item').forEach((item) => {
      add(item, 'v-timeline-item');
      const marker = item.querySelector('.timeline-marker,.timeline-dot,.v-timeline-item__marker');
      if (marker) add(marker, 'v-timeline-item__marker');
      const content = item.querySelector('.timeline-content,.v-timeline-item__content') || Array.from(item.children).find((child) => child !== marker);
      if (content) {
        add(content, 'v-grow', 'v-stack-2');
        const title = content.querySelector('strong,h3,h4');
        const desc = content.querySelector('span:not([data-v-icon])');
        const meta = content.querySelector('small');
        if (title) add(title, 'v-label');
        if (desc) add(desc, 'v-body-sm');
        if (meta) add(meta, 'v-caption', 'v-muted');
      }
      item.dataset.state = item.classList.contains('is-warning') ? 'warning' : 'default';
    });

    qsa(root, '[data-ds-component="DS v2 / Audit Item"],.ac310-audit-item').forEach((item) => {
      add(item, 'v-audit-item');
      const type = lower(item.dataset.dsPropType || item.dataset.type || 'default');
      item.dataset.type = type || 'default';
      const copy = item.querySelector('.ac310-audit-item__copy,.v-audit-item__copy');
      if (copy) {
        add(copy, 'v-audit-item__copy');
        const title = copy.querySelector('strong,h3,h4');
        const meta = copy.querySelector('small,span');
        if (title) add(title, 'v-audit-item__title');
        if (meta && meta !== title) add(meta, 'v-audit-item__meta');
      }
    });
  }

  function normalizeGenericActionCards(root) {
    qsa(root, '.generic-card-list').forEach((list) => add(list, 'v-stack-2'));
    qsa(root, '.generic-data-card').forEach((card) => {
      add(card, 'v-action-row');
      const copy = card.querySelector('.generic-card-copy');
      if (copy) {
        add(copy, 'v-action-row__copy');
        const title = copy.querySelector('strong,[data-ds-component="VCardTitle"]');
        const desc = copy.querySelector('span:not(.v-badge),small,p');
        if (title) add(title, 'v-action-row__title');
        if (desc && desc !== title) add(desc, 'v-action-row__description');
      }
      const iconBox = card.querySelector('.generic-card-icon');
      if (iconBox) add(iconBox, 'v-shrink-0');
      const badge = card.querySelector('.v-badge,[data-ds-component="VBadge"]');
      if (badge) add(badge, 'v-shrink-0');
    });
  }

  function normalizeValuationAllocations(root) {
    qsa(root, '.v460-method-summary').forEach((card) => {
      add(card, 'v-summary-card', 'v-card');
      const title = card.querySelector('strong');
      const desc = card.querySelector('span,p,small');
      if (title) add(title, 'v-label');
      if (desc && desc !== title) add(desc, 'v-body-sm', 'v-muted');
    });
    qsa(root, '.v460-allocation-list').forEach((list) => add(list, 'v-stack-2'));
    qsa(root, '.v460-allocation-row').forEach((row) => {
      add(row, 'v-action-row');
      const children = Array.from(row.children);
      const copy = children[0];
      const trailing = children[1];
      if (copy) {
        add(copy, 'v-action-row__copy');
        const title = copy.querySelector('strong');
        if (title) add(title, 'v-action-row__title');
        const smalls = Array.from(copy.querySelectorAll('small'));
        if (smalls.length) {
          const description = document.createElement('span');
          description.className = 'v-action-row__description';
          description.textContent = smalls.map((el) => el.textContent.trim()).filter(Boolean).join(' · ');
          smalls.forEach((el) => el.remove());
          copy.appendChild(description);
        }
      }
      if (trailing) add(trailing, 'v-label', 'v-shrink-0');
    });
  }

  function normalizeCompositions(root) {
    qsa(root, '.ds24-list-stack,.receipt-line-list,.bj02-record-stack,.bj02-review-products,.io-product-list,.ac310-list-stack,.ac310-form-stack,.form-stack,.quick-source-form,.v430-list,.v430-flat__rows,.ac310-audit-list,.val14-choice-list,.v460-key-stack,.v430-key-stack,.bj02-info-stack,.ds24-info-stack,.io06-result-rows,.ac310-info-rows,.ac310-key-value-stack').forEach((el) => add(el, 'v-stack-2'));
    qsa(root, '.ds24-info-group,.review-card,.io-read-card,.ac310-surface,.ac310-list-surface,.cr-fact-card,.bj05-section,.io06-section,.bj02-review-section').forEach((el) => add(el, 'v-section-block'));
    qsa(root, 'img').forEach((img) => { img.style.maxWidth = '100%'; img.style.height = 'auto'; });
  }



  function normalizeSectionHeadings(root) {
    qsa(root, '.t462-section-heading,.ds24-section-title,.io-section-title,.ac310-section-title,.bj02-section-heading,.v430-section-title,.v460-section-title').forEach((el) => {
      add(el, 'v-list-topbar');
      const title = el.querySelector('h2,h3,h4,strong,.title') || el.firstElementChild;
      const count = el.querySelector('small,.count,.meta') || (el.children.length > 1 ? el.lastElementChild : null);
      if (title) add(title, 'v-list-topbar__title');
      if (count && count !== title) add(count, 'v-list-topbar__count');
    });
  }

  function normalizeResidualFields(root) {
    qsa(root, 'input,select,textarea').forEach((control) => {
      if (control.closest('#state-switcher,.review-app')) return;
      if (control.closest('.v-search,.v-field,.v-combobox,.v-keypad-grid,.v-verification-code')) return;
      const parent = control.parentElement;
      if (!parent) return;
      add(parent, 'v-field');
      const label = parent.querySelector(':scope > label,:scope > .field-label,:scope > strong:first-child,:scope > span:first-child');
      if (label && label !== control) add(label, 'v-field__label');
      if (control.tagName === 'SELECT') {
        add(parent, 'v-select-field'); parent.dataset.kind = 'select';
        let shell = parent.querySelector(':scope > .v-select-shell');
        if (!shell) {
          shell = document.createElement('div'); shell.className='v-select-shell';
          const value=document.createElement('span'); value.className='v-select-shell__value'; value.textContent=control.options?.[control.selectedIndex]?.textContent?.trim()||control.value||'Chọn giá trị';
          const icon=document.createElement('span'); icon.dataset.vIcon='chevron-down'; icon.dataset.tone='secondary';
          shell.append(value,icon); parent.insertBefore(shell,control); shell.appendChild(control);
        }
        control.style.position='absolute'; control.style.inset='0'; control.style.opacity='0'; control.style.width='100%'; control.style.height='100%';
      } else {
        add(control,'v-control');
        parent.dataset.kind = control.tagName === 'TEXTAREA' ? 'textarea' : (control.type === 'number' ? 'number' : 'text');
      }
    });
  }

  function normalizeResidualButtons(root) {
    qsa(root, 'button').forEach((btn) => {
      if (btn.closest('.v-appbar,.v-list-row,.v-segmented,.v-tabs,.v-keypad-grid,.v-bottom-nav,.v-checkrow,.v-collapsible__header,.v-select-sheet,.v-action-sheet')) return;
      if (btn.classList.contains('v-btn') || btn.classList.contains('v-icon-btn')) return;
      const cls=lower(btn.className);
      const isIconOnly = !btn.textContent.trim() && Boolean(btn.querySelector('[data-v-icon],svg'));
      if (isIconOnly) { add(btn,'v-icon-btn'); return; }
      add(btn,'v-btn');
      const danger = /danger|destructive|delete|destroy|reject/.test(cls) || lower(btn.dataset.dsPropTone).includes('danger');
      const tertiary = /tertiary|link|ghost|text/.test(cls);
      const secondary = /secondary|outline/.test(cls);
      btn.dataset.hierarchy = danger ? 'danger' : tertiary ? 'tertiary' : secondary ? 'secondary' : (btn.dataset.hierarchy || 'secondary');
      btn.dataset.size = btn.dataset.size || 'default';
    });
  }

  function normalizeActionSheets(root) {
    qsa(root, '.action-sheet,[data-ds-component="VActionSheet"],[data-ds-component="DS v2 / Action Sheet"]').forEach((sheet)=>{
      add(sheet,'v-action-sheet');
      const handle=sheet.querySelector('.sheet-handle,.action-sheet-handle,.v-sheet-handle'); if(handle)add(handle,'v-action-sheet__handle');
      const title=sheet.querySelector('h2,h3,.action-sheet-title'); if(title)add(title,'v-action-sheet__title');
      let actions=sheet.querySelector('.action-sheet-actions,.v-action-sheet__actions'); if(actions)add(actions,'v-action-sheet__actions');
      qsa(sheet,'button').forEach((b)=>{ if(!b.closest('.v-action-sheet__actions') && actions) actions.appendChild(b); add(b,'v-action-sheet__row'); });
    });
  }

  function normalizeTabs(root) {
    qsa(root, '[data-ds-component="VTabs"],.tabs,.ds24-tabs').forEach((tabs)=>{
      add(tabs,'v-tabs'); tabs.setAttribute('data-v-tabs','');
      qsa(tabs,'button,[role="tab"]').forEach((tab)=>{add(tab,'v-tab');tab.setAttribute('data-v-tab-trigger','');if(tab.classList.contains('is-active'))tab.dataset.state='active';});
    });
  }

  function normalizeResidualLegacy(root) {
    normalizeSectionHeadings(root);
    normalizeResidualFields(root);
    normalizeActionSheets(root);
    normalizeTabs(root);
    normalizeResidualButtons(root);
  }

  function canonicalize(root) {
    normalizeShell(root);
    normalizeIcons(root);
    normalizeTypography(root);
    normalizeButtons(root);
    normalizeSearch(root);
    normalizeFields(root);
    normalizeSelection(root);
    normalizeListRows(root);
    normalizeRecordCards(root);
    normalizeLinks(root);
    normalizeCollapsibles(root);
    normalizeQuantityControls(root);
    normalizeCards(root);
    normalizeInfoRows(root);
    normalizeTimelineAudit(root);
    normalizeGenericActionCards(root);
    normalizeValuationAllocations(root);
    normalizeFeedback(root);
    normalizeFooters(root);
    normalizeOverlays(root);
    normalizeCompositions(root);
    normalizeResidualLegacy(root);
    qsa(root, '[hidden]').forEach((el) => { el.hidden = true; });
  }

  function mount(host, html, context = {}) {
    const template = document.createElement('template');
    template.innerHTML = html.trim();
    const fragment = template.content;
    const product = fragment.querySelector('[data-mobile-product]') || fragment.firstElementChild;
    if (product) {
      add(product, 'v-template');
      product.dataset.htmlDsVersion = '1.6.0';
      product.dataset.rendererVersion = '5.4.0';
      canonicalize(product);
    }
    host.replaceChildren(fragment);
    host.dispatchEvent(new CustomEvent('vet45canonicalrender', {detail:{screenId:context.screen?.id || null,state:context.state || null,flowId:context.flowId || null}, bubbles:true}));
  }

  // Canonical interactive div rows/cards preserve keyboard activation without changing business handlers.
  document.addEventListener('keydown', (event) => {
    if (event.key !== 'Enter' && event.key !== ' ') return;
    const target = event.target.closest('#app-screen [role="button"][tabindex]');
    if (!target || target.getAttribute('aria-disabled') === 'true') return;
    event.preventDefault(); target.click();
  });

  window.VET45_CANONICAL_RENDERER = { mount, canonicalize, normalizeShell };
})();
