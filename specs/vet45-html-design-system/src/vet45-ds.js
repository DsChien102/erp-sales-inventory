export const VET45_DS_VERSION = '1.5.0';
export const FIGMA_DS_VERSION = '2.0.3';
export const FIGMA_FILE_KEY = 'QVJolM5tAdFKkhP7RIwe3y';
export const FIGMA_PAGES = {
  foundations: '505:5889',
  components: '505:5890',
  patterns: '505:5891'
};

export const ICON_REGISTRY = [
  // Current Figma DS runtime glyphs (canonical names).
  'plus','ellipsis','trash-2','chevron-right','search','x','check','user','arrow-up-right','image','info',
  'circle-check','shield-alert','circle-x','chevron-down','chevron-up','loader-circle','calendar','cloud-upload',
  'file-up','chevron-left','house','receipt-text','package','handshake','users','building-2','logs','arrow-down-right',
  'clock','pencil','tag','badge-percent','banknote-arrow-down','triangle-alert','search-x','sliders-horizontal','pause',
  // Additional approved/public glyphs kept for Flutter/API compatibility; never aliases for a different glyph.
  'store','warehouse','shield-check','history','mail','send','log-out','settings','refresh-cw','lock','inbox','file-text','zap','minus'
];

const ICON_PATHS = {
  'chevron-left':'<path d="m15 18-6-6 6-6"/>',
  'chevron-right':'<path d="m9 18 6-6-6-6"/>',
  'chevron-down':'<path d="m6 9 6 6 6-6"/>',
  'chevron-up':'<path d="m18 15-6-6-6 6"/>',
  search:'<circle cx="11" cy="11" r="8"/><path d="m21 21-4.35-4.35"/>',
  'sliders-horizontal':'<line x1="21" x2="14" y1="4" y2="4"/><line x1="10" x2="3" y1="4" y2="4"/><line x1="21" x2="12" y1="12" y2="12"/><line x1="8" x2="3" y1="12" y2="12"/><line x1="21" x2="16" y1="20" y2="20"/><line x1="12" x2="3" y1="20" y2="20"/><line x1="14" x2="14" y1="2" y2="6"/><line x1="8" x2="8" y1="10" y2="14"/><line x1="16" x2="16" y1="18" y2="22"/>',
  plus:'<path d="M5 12h14M12 5v14"/>',
  pencil:'<path d="M21.17 6.83 17.17 2.83a2 2 0 0 0-2.83 0L3 14.17V21h6.83L21.17 9.66a2 2 0 0 0 0-2.83Z"/><path d="m14 4 6 6"/>',
  'trash-2':'<path d="M3 6h18M8 6V4h8v2M19 6l-1 14H6L5 6M10 11v6M14 11v6"/>',
  x:'<path d="m18 6-12 12M6 6l12 12"/>',
  check:'<path d="m5 12 4 4L19 6"/>',
  'circle-check':'<circle cx="12" cy="12" r="10"/><path d="m9 12 2 2 4-4"/>',
  'triangle-alert':'<path d="M10.29 3.86 1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0Z"/><path d="M12 9v4M12 17h.01"/>',
  'circle-x':'<circle cx="12" cy="12" r="10"/><path d="m15 9-6 6M9 9l6 6"/>',
  info:'<circle cx="12" cy="12" r="10"/><path d="M12 16v-4M12 8h.01"/>',
  user:'<path d="M19 21a7 7 0 0 0-14 0"/><circle cx="12" cy="7" r="4"/>',
  users:'<path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2M9 11a4 4 0 1 0 0-8M22 21v-2a4 4 0 0 0-3-3.87M16 3.13a4 4 0 0 1 0 7.75"/>',
  'building-2':'<path d="M6 22V4a2 2 0 0 1 2-2h8a2 2 0 0 1 2 2v18M6 12H4a2 2 0 0 0-2 2v8h20v-8a2 2 0 0 0-2-2h-2M10 6h4M10 10h4M10 14h4M10 18h4"/>',
  store:'<path d="M3 9l2-5h14l2 5M5 13v8h14v-8M9 21v-6h6v6"/><path d="M3 9a3 3 0 0 0 6 0 3 3 0 0 0 6 0 3 3 0 0 0 6 0"/>',
  warehouse:'<path d="M3 21V9l9-6 9 6v12M7 21v-8h10v8M7 16h10"/>',
  'shield-check':'<path d="M20 13c0 5-3.5 7.5-8 9-4.5-1.5-8-4-8-9V5l8-3 8 3v8Z"/><path d="m9 12 2 2 4-4"/>',
  history:'<path d="M3 12a9 9 0 1 0 3-6.7L3 8"/><path d="M3 3v5h5M12 7v5l3 2"/>',
  mail:'<rect width="20" height="16" x="2" y="4" rx="2"/><path d="m22 7-10 6L2 7"/>',
  send:'<path d="m22 2-7 20-4-9-9-4Z"/><path d="M22 2 11 13"/>',
  'log-out':'<path d="M10 17l5-5-5-5M15 12H3"/><path d="M15 3h4a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2h-4"/>',
  settings:'<path d="M12 15.5a3.5 3.5 0 1 0 0-7 3.5 3.5 0 0 0 0 7Z"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06-2.83 2.83-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21h-4v-.17a1.65 1.65 0 0 0-1-1.51 1.65 1.65 0 0 0-1.82.33l-.06.06-2.83-2.83.06-.06A1.65 1.65 0 0 0 4.6 15a1.65 1.65 0 0 0-1.51-1H3v-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06 2.83-2.83.06.06A1.65 1.65 0 0 0 8.92 4a1.65 1.65 0 0 0 1-1.51V2h4v.49A1.65 1.65 0 0 0 14.92 4a1.65 1.65 0 0 0 1.82-.33l.06-.06 2.83 2.83-.06.06A1.65 1.65 0 0 0 19.4 9c.12.5.5.88 1 1H21v4h-.6c-.5.12-.88.5-1 1Z"/>',
  ellipsis:'<circle cx="5" cy="12" r="1"/><circle cx="12" cy="12" r="1"/><circle cx="19" cy="12" r="1"/>',
  'refresh-cw':'<path d="M20 11a8 8 0 1 0-2.34 5.66L20 14"/><path d="M20 4v7h-7"/>',
  logs:'<path d="M3 3h18v18H3z"/><path d="M7 8h10M7 12h6M7 16h8"/>',
  lock:'<rect width="18" height="11" x="3" y="11" rx="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/>',
  clock:'<circle cx="12" cy="12" r="10"/><path d="M12 6v6l4 2"/>',
  inbox:'<path d="M4 4h16l2 10v6H2v-6L4 4Z"/><path d="M2 14h5l2 3h6l2-3h5"/>',
  'file-text':'<path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8Z"/><path d="M14 2v6h6M8 13h8M8 17h8M8 9h2"/>',
  zap:'<path d="M13 2 3 14h9l-1 8 10-12h-9Z"/>',
  package:'<path d="m12 2 9 5-9 5-9-5 9-5Z"/><path d="m3 7 9 5 9-5M12 12v10"/>',
  'arrow-up-right':'<path d="M7 7h10v10"/><path d="M7 17 17 7"/>',
  'arrow-down-right':'<path d="m7 7 10 10"/><path d="M17 7v10H7"/>',
  'badge-percent':'<path d="m15 9-6 6"/><path d="M9 9h.01M15 15h.01"/><path d="M12 2.5c1.3 0 2.3 1.2 3.6.9 1.2-.3 2.5.4 2.8 1.6.3 1.3 1.5 2.3.9 3.6-.6 1.1-.6 2.5 0 3.6.6 1.3-.6 2.3-.9 3.6-.3 1.2-1.6 1.9-2.8 1.6-1.3-.3-2.3.9-3.6.9-1.3 0-2.3-1.2-3.6-.9-1.2.3-2.5-.4-2.8-1.6-.3-1.3-1.5-2.3-.9-3.6.6-1.1.6-2.5 0-3.6C2.4 7.3 3.6 6.3 3.9 5c.3-1.2 1.6-1.9 2.8-1.6 1.3.3 2.3-.9 3.6-.9Z"/>',
  calendar:'<path d="M8 2v4M16 2v4"/><rect width="18" height="18" x="3" y="4" rx="2"/><path d="M3 10h18"/>',
  'cloud-upload':'<path d="M12 13v8"/><path d="m16 17-4-4-4 4"/><path d="M4.4 15.3A7 7 0 1 1 15.7 8h1.8a4.5 4.5 0 0 1 2.2 8.4"/>',
  'file-up':'<path d="M14.5 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7.5Z"/><path d="M14 2v6h6M12 18v-6"/><path d="m9 15 3-3 3 3"/>',
  handshake:'<path d="m11 17 2 2a1 1 0 1 0 3-3"/><path d="m14 14 2.5 2.5a1 1 0 1 0 3-3l-3.9-3.9a3 3 0 0 0-4.2 0L10 11a1 1 0 0 1-3-3l2.8-2.8a5.8 5.8 0 0 1 7.1-.9l.5.3a2 2 0 0 0 1.4.3L21 4"/><path d="m21 3 1 11h-2M3 3 2 14l6.5 6.5a1 1 0 1 0 3-3M3 4h8"/>',
  house:'<path d="M3 10.5 12 3l9 7.5V21a1 1 0 0 1-1 1h-5v-9H9v9H4a1 1 0 0 1-1-1Z"/>',
  'loader-circle':'<path d="M21 12a9 9 0 1 1-6.2-8.6"/>',
  pause:'<rect x="14" y="4" width="4" height="16" rx="1"/><rect x="6" y="4" width="4" height="16" rx="1"/>',
  'receipt-text':'<path d="M4 2v20l2-1 2 1 2-1 2 1 2-1 2 1 2-1 2 1V2l-2 1-2-1-2 1-2-1-2 1-2-1-2 1-2-1Z"/><path d="M16 8h-6M16 12H8M13 16H8"/>',
  'search-x':'<path d="m13.5 8.5-5 5M8.5 8.5l5 5"/><circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/>',
  'shield-alert':'<path d="M20 13c0 5-3.5 7.5-8 9-4.5-1.5-8-4-8-9V5l8-3 8 3Z"/><path d="M12 8v4M12 16h.01"/>',
  tag:'<path d="M12.6 2H4a2 2 0 0 0-2 2v8.6a2 2 0 0 0 .6 1.4l7.4 7.4a2 2 0 0 0 2.8 0l8.6-8.6a2 2 0 0 0 0-2.8L14 2.6A2 2 0 0 0 12.6 2Z"/><circle cx="7.5" cy="7.5" r=".5"/>',
  minus:'<path d="M5 12h14"/>'
};



const EXACT_ICON_SVGS = {
  plus: '<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path fill-rule="evenodd" clip-rule="evenodd" d="M4 12C4 11.4477 4.44772 11 5 11H19C19.5523 11 20 11.4477 20 12C20 12.5523 19.5523 13 19 13H5C4.44772 13 4 12.5523 4 12Z" fill="black"/><path fill-rule="evenodd" clip-rule="evenodd" d="M12 4C12.5523 4 13 4.44772 13 5V19C13 19.5523 12.5523 20 12 20C11.4477 20 11 19.5523 11 19V5C11 4.44772 11.4477 4 12 4Z" fill="black"/></svg>',
  x: '<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path fill-rule="evenodd" clip-rule="evenodd" d="M18.7071 5.29289C19.0976 5.68342 19.0976 6.31658 18.7071 6.70711L6.70711 18.7071C6.31658 19.0976 5.68342 19.0976 5.29289 18.7071C4.90237 18.3166 4.90237 17.6834 5.29289 17.2929L17.2929 5.29289C17.6834 4.90237 18.3166 4.90237 18.7071 5.29289Z" fill="black"/><path fill-rule="evenodd" clip-rule="evenodd" d="M5.29289 5.29289C5.68342 4.90237 6.31658 4.90237 6.70711 5.29289L18.7071 17.2929C19.0976 17.6834 19.0976 18.3166 18.7071 18.7071C18.3166 19.0976 17.6834 19.0976 17.2929 18.7071L5.29289 6.70711C4.90237 6.31658 4.90237 5.68342 5.29289 5.29289Z" fill="black"/></svg>',
  info: '<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path fill-rule="evenodd" clip-rule="evenodd" d="M12 3C7.02944 3 3 7.02944 3 12C3 16.9706 7.02944 21 12 21C16.9706 21 21 16.9706 21 12C21 7.02944 16.9706 3 12 3ZM1 12C1 5.92487 5.92487 1 12 1C18.0751 1 23 5.92487 23 12C23 18.0751 18.0751 23 12 23C5.92487 23 1 18.0751 1 12Z" fill="black"/><path fill-rule="evenodd" clip-rule="evenodd" d="M12 11C12.5523 11 13 11.4477 13 12V16C13 16.5523 12.5523 17 12 17C11.4477 17 11 16.5523 11 16V12C11 11.4477 11.4477 11 12 11Z" fill="black"/><path fill-rule="evenodd" clip-rule="evenodd" d="M11 8C11 7.44772 11.4477 7 12 7H12.01C12.5623 7 13.01 7.44772 13.01 8C13.01 8.55228 12.5623 9 12.01 9H12C11.4477 9 11 8.55228 11 8Z" fill="black"/></svg>',
  'circle-check': '<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path fill-rule="evenodd" clip-rule="evenodd" d="M12 3C7.02944 3 3 7.02944 3 12C3 16.9706 7.02944 21 12 21C16.9706 21 21 16.9706 21 12C21 7.02944 16.9706 3 12 3ZM1 12C1 5.92487 5.92487 1 12 1C18.0751 1 23 5.92487 23 12C23 18.0751 18.0751 23 12 23C5.92487 23 1 18.0751 1 12Z" fill="black"/><path fill-rule="evenodd" clip-rule="evenodd" d="M15.7071 9.29289C16.0976 9.68342 16.0976 10.3166 15.7071 10.7071L11.7071 14.7071C11.3166 15.0976 10.6834 15.0976 10.2929 14.7071L8.29289 12.7071C7.90237 12.3166 7.90237 11.6834 8.29289 11.2929C8.68342 10.9024 9.31658 10.9024 9.70711 11.2929L11 12.5858L14.2929 9.29289C14.6834 8.90237 15.3166 8.90237 15.7071 9.29289Z" fill="black"/></svg>',
  'triangle-alert': '<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path fill-rule="evenodd" clip-rule="evenodd" d="M10.4796 2.39428C10.9382 2.1271 11.4593 1.98633 11.99 1.98633C12.5207 1.98633 13.0419 2.1271 13.5004 2.39428C13.9583 2.66111 14.3374 3.0445 14.599 3.5054L22.5972 17.5022C22.8596 17.9575 22.9978 18.4738 22.998 18.9995C22.9981 19.5258 22.8598 20.0429 22.5968 20.4989C22.3339 20.9549 21.9556 21.3336 21.5 21.5971C21.0443 21.8607 20.5274 21.9997 20.0011 22.0002H4.0041C3.4769 22.0041 2.95796 21.869 2.49957 21.6084C2.03975 21.3471 1.6572 20.9688 1.3907 20.5119C1.12419 20.0551 0.983211 19.5359 0.98204 19.007C0.980871 18.4789 1.11911 17.9599 1.38403 17.5002L9.38003 3.50717C9.64257 3.04458 10.0217 2.66114 10.4796 2.39428ZM11.99 3.98633C11.8131 3.98633 11.6394 4.03325 11.4866 4.12231C11.3337 4.21137 11.2072 4.33938 11.1183 4.49636L3.11827 18.4964C3.02787 18.6529 2.98164 18.8262 2.98204 19.0025C2.98243 19.1788 3.02942 19.3519 3.11825 19.5042C3.20709 19.6565 3.3346 19.7826 3.48788 19.8697C3.64115 19.9568 3.81474 20.0019 4.00003 20.0002H19.999C20.1742 19.9999 20.347 19.9536 20.4986 19.8659C20.6505 19.778 20.7766 19.6518 20.8643 19.4998C20.9519 19.3478 20.998 19.1754 20.998 19C20.9979 18.8245 20.9517 18.6522 20.8618 18.4964L12.8609 4.49486C12.7728 4.33938 12.6463 4.21137 12.4935 4.12231C12.3407 4.03325 12.1669 3.98633 11.99 3.98633Z" fill="black"/><path fill-rule="evenodd" clip-rule="evenodd" d="M12 8.00023C12.5523 8.00023 13 8.44795 13 9.00023V13.0002C13 13.5525 12.5523 14.0002 12 14.0002C11.4477 14.0002 11 13.5525 11 13.0002V9.00023C11 8.44795 11.4477 8.00023 12 8.00023Z" fill="black"/><path fill-rule="evenodd" clip-rule="evenodd" d="M11 17.0002C11 16.4479 11.4477 16.0002 12 16.0002H12.01C12.5623 16.0002 13.01 16.4479 13.01 17.0002C13.01 17.5525 12.5623 18.0002 12.01 18.0002H12C11.4477 18.0002 11 17.5525 11 17.0002Z" fill="black"/></svg>',
  'circle-x': '<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path fill-rule="evenodd" clip-rule="evenodd" d="M12 3C7.02944 3 3 7.02944 3 12C3 16.9706 7.02944 21 12 21C16.9706 21 21 16.9706 21 12C21 7.02944 16.9706 3 12 3ZM1 12C1 5.92487 5.92487 1 12 1C18.0751 1 23 5.92487 23 12C23 18.0751 18.0751 23 12 23C5.92487 23 1 18.0751 1 12Z" fill="black"/><path fill-rule="evenodd" clip-rule="evenodd" d="M15.7071 8.29289C16.0976 8.68342 16.0976 9.31658 15.7071 9.70711L9.70711 15.7071C9.31658 16.0976 8.68342 16.0976 8.29289 15.7071C7.90237 15.3166 7.90237 14.6834 8.29289 14.2929L14.2929 8.29289C14.6834 7.90237 15.3166 7.90237 15.7071 8.29289Z" fill="black"/><path fill-rule="evenodd" clip-rule="evenodd" d="M8.29289 8.29289C8.68342 7.90237 9.31658 7.90237 9.70711 8.29289L15.7071 14.2929C16.0976 14.6834 16.0976 15.3166 15.7071 15.7071C15.3166 16.0976 14.6834 16.0976 14.2929 15.7071L8.29289 9.70711C7.90237 9.31658 7.90237 8.68342 8.29289 8.29289Z" fill="black"/></svg>',
  image: '<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path fill-rule="evenodd" clip-rule="evenodd" d="M5 4C4.44772 4 4 4.44772 4 5V19C4 19.5523 4.44772 20 5 20H19C19.5523 20 20 19.5523 20 19V5C20 4.44772 19.5523 4 19 4H5ZM2 5C2 3.34315 3.34315 2 5 2H19C20.6569 2 22 3.34315 22 5V19C22 20.6569 20.6569 22 19 22H5C3.34315 22 2 20.6569 2 19V5Z" fill="black"/><path fill-rule="evenodd" clip-rule="evenodd" d="M9 8C8.44772 8 8 8.44772 8 9C8 9.55228 8.44772 10 9 10C9.55228 10 10 9.55228 10 9C10 8.44772 9.55228 8 9 8ZM6 9C6 7.34315 7.34315 6 9 6C10.6569 6 12 7.34315 12 9C12 10.6569 10.6569 12 9 12C7.34315 12 6 10.6569 6 9Z" fill="black"/><path fill-rule="evenodd" clip-rule="evenodd" d="M14.379 11.2068C14.9416 10.6444 15.7045 10.3284 16.5 10.3284C17.2955 10.3284 18.0584 10.6444 18.621 11.2068L21.7071 14.2929C22.0976 14.6834 22.0976 15.3166 21.7071 15.7071C21.3166 16.0976 20.6834 16.0976 20.2929 15.7071L17.207 12.6212C17.0195 12.4337 16.7652 12.3284 16.5 12.3284C16.2349 12.3284 15.9806 12.4337 15.7931 12.6211L6.70711 21.7071C6.31658 22.0976 5.68342 22.0976 5.29289 21.7071C4.90237 21.3166 4.90237 20.6834 5.29289 20.2929L14.379 11.2068Z" fill="black"/></svg>',
  'banknote-arrow-down': '<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M21 13V8C21 7.73478 20.8946 7.48051 20.707 7.29297C20.5195 7.10543 20.2652 7 20 7H4C3.73478 7 3.4805 7.10543 3.29297 7.29297C3.10543 7.4805 3 7.73478 3 8V16C3 16.2652 3.10543 16.5195 3.29297 16.707C3.48051 16.8946 3.73478 17 4 17H12C12.5523 17 13 17.4477 13 18C13 18.5523 12.5523 19 12 19H4C3.20435 19 2.44151 18.6837 1.87891 18.1211C1.3163 17.5585 1 16.7956 1 16V8C1 7.20435 1.3163 6.44152 1.87891 5.87891C2.44152 5.3163 3.20435 5 4 5H20C20.7957 5 21.5585 5.3163 22.1211 5.87891C22.6837 6.44152 23 7.20435 23 8V13C23 13.5523 22.5523 14 22 14C21.4477 14 21 13.5523 21 13Z" fill="black"/><path d="M21.293 18.293C21.6835 17.9024 22.3165 17.9024 22.707 18.293C23.0976 18.6835 23.0976 19.3165 22.707 19.707L19.707 22.707C19.3165 23.0976 18.6835 23.0976 18.293 22.707L15.293 19.707C14.9024 19.3165 14.9024 18.6835 15.293 18.293C15.6835 17.9024 16.3165 17.9024 16.707 18.293L19 20.5859L21.293 18.293Z" fill="black"/><path d="M18.0098 11C18.562 11 19.0098 11.4477 19.0098 12C19.0098 12.5523 18.562 13 18.0098 13H18C17.4477 13 17 12.5523 17 12C17 11.4477 17.4477 11 18 11H18.0098Z" fill="black"/><path d="M18 22V16C18 15.4477 18.4477 15 19 15C19.5523 15 20 15.4477 20 16V22C20 22.5523 19.5523 23 19 23C18.4477 23 18 22.5523 18 22Z" fill="black"/><path d="M6.00977 11C6.56205 11 7.00977 11.4477 7.00977 12C7.00977 12.5523 6.56205 13 6.00977 13H6C5.44772 13 5 12.5523 5 12C5 11.4477 5.44772 11 6 11H6.00977Z" fill="black"/><path d="M13 12C13 11.4477 12.5523 11 12 11C11.4477 11 11 11.4477 11 12C11 12.5523 11.4477 13 12 13C12.5523 13 13 12.5523 13 12ZM15 12C15 13.6569 13.6569 15 12 15C10.3431 15 9 13.6569 9 12C9 10.3431 10.3431 9 12 9C13.6569 9 15 10.3431 15 12Z" fill="black"/></svg>'
};

export const VICON_ALIASES = {
  chevronLeft:'chevron-left', chevronLeftRounded:'chevron-left',
  chevronRight:'chevron-right', chevronRightRounded:'chevron-right',
  chevronDown:'chevron-down', expandMore:'chevron-down', arrowDropDown:'chevron-down', chevronUp:'chevron-up', expandLess:'chevron-up', expandLessRounded:'chevron-up', arrowDropUp:'chevron-up',
  search:'search', add:'plus', close:'x', delete:'trash-2', edit:'pencil', refresh:'refresh-cw', moreHoriz:'ellipsis', tune:'sliders-horizontal', check:'check', logout:'log-out', image:'image', banknoteArrowDown:'banknote-arrow-down', minus:'minus', arrowUpRight:'arrow-up-right', arrowDownRight:'arrow-down-right', badgePercent:'badge-percent', calendar:'calendar', cloudUpload:'cloud-upload', fileUp:'file-up', handshake:'handshake', home:'house', receiptText:'receipt-text', searchX:'search-x', shieldAlert:'shield-alert', tag:'tag', pause:'pause',
  warning:'triangle-alert', error:'circle-x', success:'circle-check', info:'info', people:'users', group:'users', store:'store', apartment:'building-2', person:'user', description:'file-text',
  warehouse:'warehouse', history:'history', inbox:'inbox', lock:'lock', settings:'settings', mail:'mail', send:'send', bolt:'zap', clock:'clock', pencil:'pencil'
};

export function resolveIconName(name) {
  if (ICON_REGISTRY.includes(name)) return name;
  const alias = VICON_ALIASES[name];
  return alias && ICON_REGISTRY.includes(alias) ? alias : null;
}

export function icon(name, { size = 20, tone = 'primary', label = '', strict = false } = {}) {
  const resolved = resolveIconName(name);
  if (!resolved) {
    if (strict) throw new Error(`VET45 HTML DS: icon "${name}" is not in the approved local product registry.`);
    const a11y = label ? ` aria-label="${label}" role="img"` : ' aria-hidden="true"';
    return `<span class="v-icon v-icon--missing" style="--v-icon-size:${size}px"${a11y} data-icon-missing="${String(name)}"></span>`;
  }
  const color = `var(--vet45-v2-icon-${String(tone).toLowerCase()})`;
  const exact = EXACT_ICON_SVGS[resolved];
  if (exact) {
    return exact
      .replace('<svg ', `<svg class="v-icon" style="color:${color}" width="${size}" height="${size}" `)
      .replace(/ width="24" height="24"/, '')
      .replace(/fill="black"/g, 'fill="currentColor"')
      .replace('xmlns="http://www.w3.org/2000/svg"', `xmlns="http://www.w3.org/2000/svg" ${label ? `aria-label="${label}" role="img"` : 'aria-hidden="true"'} data-icon="${resolved}"`);
  }
  return `<svg class="v-icon" width="${size}" height="${size}" viewBox="0 0 24 24" fill="none" stroke="${color}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"${label ? ` aria-label="${label}" role="img"` : ' aria-hidden="true"'} data-icon="${resolved}">${ICON_PATHS[resolved] || ''}</svg>`;
}

function hydrateIcons(root) {
  root.querySelectorAll('[data-v-icon]').forEach((el) => {
    if (el.dataset.vHydrated) return;
    el.innerHTML = icon(el.dataset.vIcon, {
      size: Number(el.dataset.size || 20),
      tone: el.dataset.tone || 'primary',
      label: el.getAttribute('aria-label') || ''
    });
    el.dataset.vHydrated = '1';
  });
}

function wireCollapsibles(root) {
  root.querySelectorAll('[data-v-collapsible]').forEach((el) => {
    const apply = () => {
      const expanded = el.hasAttribute('open') || el.dataset.state === 'expanded';
      el.dataset.state = expanded ? 'expanded' : 'collapsed';
      const chevron = el.querySelector('[data-v-collapsible-chevron]');
      if (chevron) chevron.dataset.vIcon = expanded ? 'chevron-up' : 'chevron-down';
    };
    apply();
    el.addEventListener('toggle', () => { apply(); hydrateIcons(el); });
  });
}

function wireStateControls(root) {
  root.querySelectorAll('[data-v-toggle-state]').forEach((el) => {
    el.addEventListener('click', () => {
      if (el.dataset.state?.startsWith('disabled')) return;
      const on = el.dataset.state === 'on';
      el.dataset.state = on ? 'off' : 'on';
      el.setAttribute('aria-checked', String(!on));
    });
  });
}


function wireTabs(root) {
  root.querySelectorAll('[data-v-tabs]').forEach((tabs) => {
    const triggers = [...tabs.querySelectorAll('[data-v-tab-trigger]')];
    const panels = [...tabs.querySelectorAll('[data-v-tab-content]')];
    const select = (idx, focus = false) => {
      const target = triggers[idx];
      if (!target || target.dataset.state === 'disabled' || target.disabled) return;
      triggers.forEach((el, i) => {
        const active = i === idx;
        el.dataset.state = active ? 'active' : (el.dataset.state === 'disabled' ? 'disabled' : 'default');
        el.setAttribute('aria-selected', String(active));
        el.tabIndex = active ? 0 : -1;
        if (focus && active) el.focus();
      });
      panels.forEach((el, i) => { el.hidden = i !== idx; });
      tabs.dataset.selectedIndex = String(idx);
      tabs.dispatchEvent(new CustomEvent('vtabchange', { bubbles: true, detail: { index: idx } }));
    };
    triggers.forEach((el, i) => {
      el.addEventListener('click', () => select(i));
      el.addEventListener('keydown', (event) => {
        if (!['ArrowLeft','ArrowRight','Home','End'].includes(event.key)) return;
        event.preventDefault();
        let next = i;
        if (event.key === 'Home') next = 0;
        else if (event.key === 'End') next = triggers.length - 1;
        else next = (i + (event.key === 'ArrowRight' ? 1 : -1) + triggers.length) % triggers.length;
        for (let guard=0; guard<triggers.length && (triggers[next].dataset.state==='disabled'||triggers[next].disabled); guard++) next=(next+(event.key==='ArrowLeft'?-1:1)+triggers.length)%triggers.length;
        select(next, true);
      });
    });
    const initial = Number(tabs.dataset.selectedIndex || Math.max(0, triggers.findIndex(x => x.dataset.state === 'active')));
    if (triggers.length) select(initial < 0 ? 0 : initial);
  });
}

function wireCombobox(root) {
  root.querySelectorAll('[data-v-combobox]').forEach((box) => {
    const content = box.querySelector('[data-v-combobox-content]');
    const input = box.querySelector('input');
    const setOpen = (open) => {
      if (!content || box.dataset.state === 'disabled') return;
      content.hidden = !open; box.dataset.open = String(open);
      input?.setAttribute('aria-expanded', String(open));
    };
    box.querySelector('[data-v-combobox-toggle]')?.addEventListener('click', () => setOpen(box.dataset.open !== 'true'));
    input?.addEventListener('focus', () => setOpen(true));
    box.querySelectorAll('[data-v-combobox-item]').forEach((item) => item.addEventListener('click', () => {
      if (item.dataset.disabled === 'true') return;
      box.querySelectorAll('[data-v-combobox-item]').forEach(x => x.dataset.selected = 'false');
      item.dataset.selected = 'true';
      if (input) input.value = item.dataset.label || item.textContent.trim();
      setOpen(false);
      box.dispatchEvent(new CustomEvent('vcomboboxchange',{bubbles:true,detail:{value:item.dataset.value ?? item.dataset.label ?? item.textContent.trim()}}));
    }));
    document.addEventListener('pointerdown', (event) => { if (!box.contains(event.target)) setOpen(false); });
  });
}

function wirePasswordFields(root) {
  root.querySelectorAll('[data-v-password-toggle]').forEach((toggle) => {
    const field = toggle.closest('[data-v-password-field]') || toggle.parentElement;
    const input = field?.querySelector('input');
    if (!input) return;
    toggle.addEventListener('click', () => {
      const visible = input.type === 'text';
      input.type = visible ? 'password' : 'text';
      toggle.setAttribute('aria-pressed', String(!visible));
    });
  });
}

function wireVerificationCode(root) {
  root.querySelectorAll('[data-v-verification-code]').forEach((group) => {
    const cells=[...group.querySelectorAll('input')];
    cells.forEach((cell,i)=>{
      cell.addEventListener('input',()=>{ if(cell.value && i<cells.length-1) cells[i+1].focus(); if(cells.every(x=>x.value)) group.dispatchEvent(new CustomEvent('vcomplete',{bubbles:true,detail:{value:cells.map(x=>x.value).join('')}})); });
      cell.addEventListener('keydown',(e)=>{ if(e.key==='Backspace'&&!cell.value&&i>0) cells[i-1].focus(); });
    });
  });
}
export function initVet45DS(root = document) {
  hydrateIcons(root);
  wireCollapsibles(root);
  wireStateControls(root);
  wireTabs(root);
  wireCombobox(root);
  wirePasswordFields(root);
  wireVerificationCode(root);
}

if (typeof document !== 'undefined') {
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', () => initVet45DS());
  else initVet45DS();
}
