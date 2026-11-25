// Prototype Theme 1 (TH-01) + Web cho app (10-8). Không có ?screen= → trang xem (viewer.js); có → vẽ đúng một ca (URL chụp ảnh).
// iPhone: bố cục thiết kế lại 2026-11-25 (app/*.js; chữ và trạng thái chép Flutter, nguồn Dart ghi ở đầu từng file). Web: bố cục thiết kế lại (app/web/*.js) — sửa web không đụng iPhone.
// Đợt 1 — màn công khai; đợt 2 — quản trị; đợt 3 — tài khoản: màn công khai ngoài ShellRoute(StoreShell); route /more/* của Theme 1 trong ShellRoute (web ≥ 1024 có thanh bên 84). Ảnh vẽ trang trần nên không có thanh bên / thanh dưới.
import { DEVICE } from '../shared/shell.js';
import { SCREENS } from './cases.js';
import { bare, isSplit } from './ds.js';
import * as invitation from './invitation.js';
import * as invitationWeb from './web/invitation.js';
import * as login from './login.js';
import * as loginWeb from './web/login.js';
import * as reset from './reset.js';
import * as resetWeb from './web/reset.js';
import * as signup from './signup.js';
import * as signupWeb from './web/signup.js';
import * as verify from './verify.js';
import * as verifyWeb from './web/verify.js';
import * as org from './org.js';
import * as orgWeb from './web/org.js';
import * as users from './users.js';
import * as usersWeb from './web/users.js';
import * as roles from './roles.js';
import * as rolesWeb from './web/roles.js';
import * as audit from './audit.js';
import * as auditWeb from './web/audit.js';
import * as account from './account.js';
import * as accountWeb from './web/account.js';

// [màn iPhone, màn web (app/web, thiết kế lại 2026-11-24)]
const PAGES = {
  login: [login.loginPage, loginWeb.loginPage],
  signup: [signup.signupPage, signupWeb.signupPage],
  verify: [verify.verifyPage, verifyWeb.verifyPage],
  reset: [reset.resetPage, resetWeb.resetPage],
  'no-org': [verify.noOrgPage, verifyWeb.noOrgPage],
  invitation: [invitation.invitationPage, invitationWeb.invitationPage],
  'org-profile': [org.profilePage, orgWeb.profilePage],
  'org-edit': [org.editPage, orgWeb.editPage],
  'org-legal': [org.legalPage, orgWeb.legalPage],
  users: [users.usersPage, usersWeb.usersPage],
  invite: [users.invitePage, usersWeb.invitePage],
  'invitation-detail': [users.invitationDetailPage, usersWeb.invitationDetailPage],
  'member-detail': [users.memberDetailPage, usersWeb.memberDetailPage],
  'select-role': [users.selectRolePage, usersWeb.selectRolePage],
  roles: [roles.rolesPage, rolesWeb.rolesPage],
  audit: [audit.auditPage, auditWeb.auditPage],
  'audit-detail': [audit.auditDetailPage, auditWeb.auditDetailPage],
  account: [account.accountPage, accountWeb.accountPage],
  'account-edit': [account.editAccountPage, accountWeb.editAccountPage],
};

/** Trạng thái ban đầu của một ca. */
export function caseView(screen, state, device) {
  const scr = SCREENS.find((s) => s.id === screen) || SCREENS[0];
  const st = scr.states.some(([id]) => id === state) ? state : scr.states[0][0];
  const d = DEVICE[device] ? device : 'iphone';
  let location = scr.route;
  if (scr.id === 'reset' && st === 'from-account') location = '/more/my-account/reset-password';
  if (scr.id === 'roles' && st.startsWith('detail')) location = '/more/roles/staff';
  return { screen: scr.id, state: st, device: d, width: DEVICE[d].w, height: DEVICE[d].h, location };
}

export function renderView(v) {
  const { page, overlay = '' } = PAGES[v.screen][isSplit(v.width) ? 1 : 0](v);
  return bare(v, page, overlay);
}

export function render(screen, state, device) {
  return renderView(caseView(screen, state, device));
}

// ---------------------------------------------------------------- chạy trong trình duyệt
if (typeof document !== 'undefined') {
  const q = new URLSearchParams(location.search);
  if (!q.get('screen')) {
    import('./viewer.js').then((m) => m.mountViewer(document.getElementById('root')));
  } else {
    const v = caseView(q.get('screen'), q.get('state'), q.get('device') === 'web' ? 'web' : 'iphone');
    document.getElementById('root').innerHTML = `<div class="sh-stage" data-device="${v.device}">${renderView(v)}</div>`;
  }
}
