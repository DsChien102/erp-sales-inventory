import { icon } from './icon.js';

export const esc = (s) => String(s ?? '').replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));

export function statusBar() { return '<div class="app-statusbar"><span>09:41</span><span>LTE&nbsp;&nbsp;100%</span></div>'; }

export function appbar(title, { back = true } = {}) {
  return `<header class="app-header"><div class="app-appbar ${back ? 'has-back' : 'no-back'}">${back ? `<button class="app-icon-button app-back-button" type="button" aria-label="Quay lại" data-back>${icon('chevronLeft', 'icon--24')}</button>` : ''}<div class="app-appbar-copy"><h3>${esc(title)}</h3></div></div></header>`;
}

/** Khung một màn: iPhone có status bar. footer = HTML thanh dưới. */
export function page({ title, body, footer = '', back = true, device, scroll = true }) {
  return `<div class="rc-page">${device === 'iphone' ? statusBar() : ''}${appbar(title, { back })}<div class="rc-body${scroll ? '' : ' rc-body--fixed'}">${body}</div>${footer ? `<div class="rc-footer">${footer}</div>` : ''}</div>`;
}

export function dueBadge(l) {
  const warn = l.kind === 'overdue';
  return `<span class="rc-due rc-due--${l.kind}">${warn ? icon('alert', 'icon--sm') : ''}<span>${esc(l.text)}</span></span>`;
}

export function inactiveBadge() { return '<span class="ds24-badge ds24-badge--neutral">Ngừng hoạt động</span>'; }

export function btn(label, { kind = 'primary', attrs = '', disabled = false, full = false } = {}) {
  return `<button class="button button--${kind}${full ? ' button--full' : ''}" type="button" ${attrs}${disabled ? ' disabled' : ''}>${esc(label)}</button>`;
}

export function empty({ title, description = '', action = '', actionAttrs = '', iconName = 'inbox' }) {
  return `<div class="ds24-empty"><div class="ds24-empty__media">${icon(iconName, 'icon--48')}</div><h3>${esc(title)}</h3>${description ? `<p>${esc(description)}</p>` : ''}${action ? btn(action, { kind: 'secondary', attrs: actionAttrs }) : ''}</div>`;
}

export function skeletonRows(n) {
  return `<div class="skeleton-stack">${Array.from({ length: n }, () => '<div class="skeleton skeleton--row"></div>').join('')}</div>`;
}

export function sheet({ title, body, actions = '', device }) {
  if (device === 'web') return dialog({ title, body, actions });
  return `<div class="sheet-backdrop"><section class="bottom-sheet rc-sheet" role="dialog" aria-modal="true" aria-label="${esc(title)}"><div class="sheet-handle"></div><div class="sheet-title"><h3>${esc(title)}</h3></div><div class="sheet-divider"></div><div class="sheet-content">${body}</div><div class="sheet-actions">${actions}</div></section></div>`;
}

export function dialog({ title, body = '', actions = '' }) {
  return `<div class="confirm-backdrop"><section class="confirm-dialog rc-dialog" role="dialog" aria-modal="true" aria-label="${esc(title)}"><h3>${esc(title)}</h3>${body ? `<div class="rc-dialog__body">${body}</div>` : ''}<div class="confirm-dialog-actions">${actions}</div></section></div>`;
}

export function toast(text) {
  return `<div class="toast rc-toast" role="status">${icon('check')}<span>${esc(text)}</span></div>`;
}
