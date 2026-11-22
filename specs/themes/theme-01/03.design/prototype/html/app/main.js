// Prototype Theme 1 (TH-01) + Web cho app (10-8). Không có ?screen= → trang xem (viewer.js); có → vẽ đúng một ca (URL chụp ảnh).
// Vẽ y nguyên Flutter hiện tại (không thiết kế lại) để người dùng rà bằng impeccable. Nguồn Dart ghi ở đầu từng file màn.
// Đợt 1 — màn công khai; đợt 2 — quản trị; đợt 3 — tài khoản: đều ngoài ShellRoute(StoreShell) → không thanh bên / thanh dưới trên mọi khổ (kể cả web).
import { DEVICE } from '../shared/shell.js';
import { SCREENS } from './cases.js';
import { bare } from './ds.js';
import { invitationPage } from './invitation.js';
import { loginPage } from './login.js';
import { resetPage } from './reset.js';
import { signupPage } from './signup.js';
import { noOrgPage, verifyPage } from './verify.js';
import { editPage, legalPage, profilePage } from './org.js';
import { invitationDetailPage, invitePage, memberDetailPage, selectRolePage, usersPage } from './users.js';
import { rolesPage } from './roles.js';
import { auditDetailPage, auditPage } from './audit.js';
import { accountPage, editAccountPage } from './account.js';

const PAGES = {
  login: loginPage, signup: signupPage, verify: verifyPage, reset: resetPage, 'no-org': noOrgPage, invitation: invitationPage,
  'org-profile': profilePage, 'org-edit': editPage, 'org-legal': legalPage, users: usersPage, invite: invitePage,
  'invitation-detail': invitationDetailPage, 'member-detail': memberDetailPage, 'select-role': selectRolePage, roles: rolesPage,
  audit: auditPage, 'audit-detail': auditDetailPage, account: accountPage, 'account-edit': editAccountPage,
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
  const { page, overlay = '' } = PAGES[v.screen](v);
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
