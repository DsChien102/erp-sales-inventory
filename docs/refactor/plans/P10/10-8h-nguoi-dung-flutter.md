# 10-8h Người dùng, lời mời, vai trò thành viên — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** ID-14…18 có bố cục iPhone và web đúng prototype Theme 1 (web là bảng toàn màn, chi tiết toàn màn); sửa lỗi 9, 10, 11; đổi vai trò qua một sheet xác nhận; bảng web có "Hoạt động gần nhất"; sửa kèm 12 lỗi thấy khi đọc code (Q10–Q21).

**Architecture:** `UsersAreaShell` giữ ShellRoute và `OrganizationUsersCubit` nhưng thôi chia cột. Trang danh sách / chi tiết giữ cubit, điều hướng, toast; bố cục `Narrow` / `Wide`. Web mở chi tiết bằng `context.go` (URL đổi, ← về danh sách), hẹp bằng `context.push`. Mọi thay đổi ở chi tiết báo qua `onMutated`, danh sách không tự tải lại khi chỉ xem rồi quay về. Bảng dùng chung `AdminTable` (10-8i dùng lại).

**Tech Stack:** Flutter, flutter_bloc, go_router, `c45_design_system` 1.10.0, Postgres plpgsql (Supabase).

**Spec:** bản thiết kế "10-8: Theme 1 về Flutter" duyệt trong chat 2026-11-25, phần chung ở [10-8d](10-8d-nen-theme1-flutter.md#thiết-kế-đã-duyệt-phần-chung-cho-10-8dk). Nguồn hình: `specs/themes/theme-01/03.design/prototype/html/app/users.js`, `app/web/users.js`. **Làm sau 10-8d, 10-8e, 10-8g** (`isWideLayout`, `FlowCard`, `detail_layout.dart`).

## Global Constraints

- Chữ, câu lỗi, RPC, route, `Key` (`users_invite`, `users_tabs`) giữ nguyên, trừ điều ghi ở Quyết định. Route `/more/users/select-role`, `/more/users/preview-role-change` vẫn redirect.
- Migration mới `supabase/migrations/20261128001_iam_list_members_last_activity.sql`; không sửa migration cũ, không đổi chữ ký RPC; thêm vào `REGISTRY.yaml`. Kiểm DB: `tools/db_check.sh iam_member_list`. Chạy DB và `db push`: người dùng.
- iPhone giữ "Thao tác" + sheet ở ID-16, ID-17; web nút nằm trong khối (TH-01 US-06.3, US-06.4).
- Màu `context.vColors` / `VColors`, `VSpacing`, `VRadius`, `VTypography`.
- Chỉ chạy test liệt kê ở từng task; **không** chạy `flutter test` toàn app.

## Quyết định

| # | Quyết định | Lý do |
|---|---|---|
| Q1 | `list_tenant_members` thêm khoá `last_activity_at` = `auth.users.last_sign_in_at` (cùng nguồn với `iam._membership_detail_json`). App chưa thấy khoá (DB chưa áp migration) → "—" | Web có cột "Hoạt động gần nhất" |
| Q2 | Bảng web: cột "Hoạt động gần nhất" chỉ có giá trị khi thành viên đang hoạt động, còn lại "—" | `web/users.js:44-53` |
| Q3 | **Lỗi 9:** bộ lọc lời mời: Trạng thái = Tất cả / Đang chờ / Hết hạn / Thu hồi (`revoked`, RPC nhận); Kết quả gửi = Tất cả / Đã gửi / Gửi lỗi; danh sách trống: "Chưa có lời mời nào" / "Tạo lời mời mới để thêm người dùng vào tổ chức." | TH-01 US-06.1 FR-05, FR-06 |
| Q4 | **Lỗi 10:** thiếu email và vai trò → cả hai ô báo "Vui lòng nhập email và chọn vai trò." | US-06.2 FR-06 |
| Q5 | **Lỗi 11:** "Lý do thu hồi" có `*`; khe 16 giữa câu mô tả và ô | US-06.3 FR-03 |
| Q6 | **Đổi vai trò:** "Tiếp tục" mở `showChangeRoleBottomSheet` (dùng `MembershipLifecycleConfirmSheet`): tiêu đề "Đổi vai trò của `<tên>`?", mô tả "Vai trò `<cũ>` → `<mới>`." xuống dòng "Vai trò là nhãn công việc; quyền nghiệp vụ của thành viên không thay đổi.", nút "Xác nhận thay đổi" / "Quay lại". Sheet chờ `cubit.changeRole`; thành công → đóng sheet và trang chọn; lỗi → toast, sheet còn. "Quay lại" giữ lựa chọn. `OrganizationSelectRolePage` nhận `Future<bool> Function(String roleCode) onConfirm` | Thiết kế đã duyệt |
| Q7 | Xoá `OrganizationPreviewRoleChangePage`, export và test của nó | Không route nào mở |
| Q8 | Chọn vai trò (ID-18) và nhóm radio mời (ID-15) lấy mô tả từ `IamRoleLabelMapper.description`; vai trò lạ không có mô tả | Một nguồn chữ |
| Q9 | Web ID-14: nút "Mời thành viên" trên app bar (`Key('users_invite')`); hẹp: thanh dưới, ẩn khi lỗi / không quyền / trống không lọc (khối rỗng đã có nút) | `users.js:60-65` |
| Q10 | **Sửa kèm:** `OrganizationUsersState.isMemberFiltered` (tìm, trạng thái, **vai trò**) dùng cho khối rỗng, phụ đề, `buildWhen`; phụ đề lời mời dùng `isInvitationFiltered` | Lọc vai trò không ra ai đang hiện "Chưa có thành viên khác" + "Mời thành viên" |
| Q11 | **Sửa kèm:** khi có tiêu chí xử lý ở app (vai trò, sắp xếp; kết quả gửi, thời gian, sắp hết hạn) thì nạp hết trang (`limit: 100`, lặp tới khi hết `nextCursor`) | Đang lọc / sắp trên 20 dòng đầu; trang đầu không khớp thì danh sách rỗng và không cuộn để nạp tiếp được |
| Q12 | **Sửa kèm:** sắp tên theo `VTextNormalizer.normalizeForSearch`, bằng nhau thì so chuỗi gốc | "Đ", "Á" đang xuống cuối |
| Q13 | **Sửa kèm:** mỗi lần `loadMembers` / `loadInvitations` tăng số thứ tự; trả lời cũ bị bỏ | Đổi lọc / gõ nhanh thì kết quả cũ về sau ghi đè |
| Q14 | **Sửa kèm:** "Tùy chọn" so theo ngày Việt Nam: từ `DateTime.utc(y, m, d)` − 7 giờ tới hết ngày cuối − 7 giờ | Đang so theo ngày UTC, lời mời tạo 00:00–07:00 rơi sang ngày trước |
| Q15 | **Sửa kèm:** nạp thêm trang lỗi → giữ danh sách, `loadingMore… = false`, toast "Không tải thêm được" + câu lỗi; không chuyển màn lỗi | Đang thay cả danh sách bằng màn lỗi |
| Q16 | **Sửa kèm:** `revoke` không đặt `successMessage`; trang hiện toast "Đã thu hồi lời mời." đúng một lần và gọi `onMutated` | Đang hiện hai toast |
| Q17 | **Sửa kèm:** chi tiết không có `last_activity_at` → "—", không lấy ngày tham gia | Giá trị giả (TH-01 US-06.4 FR-05) |
| Q18 | **Sửa kèm:** dòng "Danh tính: Chỉ đọc" → "Quyền sở hữu: Thành viên"; chủ: "Quyền sở hữu: Chủ sở hữu" (ID-17, ID-18, hai khung) | "Chỉ đọc" đọc như quyền chỉ xem |
| Q19 | **Sửa kèm:** mời xong quay về danh sách → chọn tab "Lời mời" rồi tải lại | Đang ở tab Thành viên, không thấy lời mời vừa gửi |
| Q20 | **Sửa kèm:** lời mời đã chấp nhận / từ chối / thu hồi không ghi hạn. `InvitationUiModel` thêm `expiryLabel` (rỗng khi kết thúc, trừ hết hạn), `deliveryLabel` (`unknown` / lạ → "—") | Đang ghi "Hết hạn sau n ngày" cho lời mời đã thu hồi, in mã gửi thô |
| Q21 | **Sửa kèm:** gợi ý ô email mời `nhanvien@example.com`; mô tả `store_owner` ở `IamRoleLabelMapper` → "Quản lý toàn bộ cửa hàng" | Tên cửa hàng mẫu khác; ghi chú kỹ thuật "BR-36" lộ ra UI |
| Q22 | Hẹp: bỏ `loadMembers(reset: true)` khi quay về từ chi tiết; `onMutated` gọi ở **cả hai** khổ | Danh sách đang chớp về màn tải dù không đổi gì |
| Q23 | Chữ viết tắt: danh sách / chi tiết lấy ký tự đầu của **từ cuối** tên, viết hoa; lời mời lấy ký tự đầu email. Tên rỗng → "?" | `web/users.js:15` |
| Q24 | Web nút ở khối "Trạng thái truy cập" / "Thông tin lời mời" tắt khi `isSubmitting`; nút của việc đang chạy có vòng xoay (`activeMutation`) | Web không còn nút "Thao tác" để xoay |

## Ảnh

Nguồn: `tools/proto-final/`, chép 2026-11-25; mọi ảnh chụp lại ở Task 1 sau khi sửa prototype; thêm ca mới `select-role__confirm`. Cột Flutter: golden `img/10-8h/flutter-<ca>-{390,1280}.png`.

| Ca | Proto 390 | Flutter 390 | Proto 1280 | Flutter 1280 |
|---|---|---|---|---|
| users__members | ![](img/10-8h/proto-users__members-390.png) | ![](img/10-8h/flutter-users__members-390.png) | ![](img/10-8h/proto-users__members-1280.png) | ![](img/10-8h/flutter-users__members-1280.png) |
| users__invitations | ![](img/10-8h/proto-users__invitations-390.png) | ![](img/10-8h/flutter-users__invitations-390.png) | ![](img/10-8h/proto-users__invitations-1280.png) | ![](img/10-8h/flutter-users__invitations-1280.png) |
| users__loading | ![](img/10-8h/proto-users__loading-390.png) | ![](img/10-8h/flutter-users__loading-390.png) | ![](img/10-8h/proto-users__loading-1280.png) | ![](img/10-8h/flutter-users__loading-1280.png) |
| users__invitations-empty | ![](img/10-8h/proto-users__invitations-empty-390.png) | ![](img/10-8h/flutter-users__invitations-empty-390.png) | ![](img/10-8h/proto-users__invitations-empty-1280.png) | ![](img/10-8h/flutter-users__invitations-empty-1280.png) |
| users__no-results | ![](img/10-8h/proto-users__no-results-390.png) | ![](img/10-8h/flutter-users__no-results-390.png) | ![](img/10-8h/proto-users__no-results-1280.png) | ![](img/10-8h/flutter-users__no-results-1280.png) |
| users__forbidden | ![](img/10-8h/proto-users__forbidden-390.png) | ![](img/10-8h/flutter-users__forbidden-390.png) | ![](img/10-8h/proto-users__forbidden-1280.png) | ![](img/10-8h/flutter-users__forbidden-1280.png) |
| users__filter-applied | ![](img/10-8h/proto-users__filter-applied-390.png) | ![](img/10-8h/flutter-users__filter-applied-390.png) | ![](img/10-8h/proto-users__filter-applied-1280.png) | ![](img/10-8h/flutter-users__filter-applied-1280.png) |
| users__filter-invitations | ![](img/10-8h/proto-users__filter-invitations-390.png) | ![](img/10-8h/flutter-users__filter-invitations-390.png) | ![](img/10-8h/proto-users__filter-invitations-1280.png) | ![](img/10-8h/flutter-users__filter-invitations-1280.png) |
| invite__empty | ![](img/10-8h/proto-invite__empty-390.png) | ![](img/10-8h/flutter-invite__empty-390.png) | ![](img/10-8h/proto-invite__empty-1280.png) | ![](img/10-8h/flutter-invite__empty-1280.png) |
| invite__filled | ![](img/10-8h/proto-invite__filled-390.png) | ![](img/10-8h/flutter-invite__filled-390.png) | ![](img/10-8h/proto-invite__filled-1280.png) | ![](img/10-8h/flutter-invite__filled-1280.png) |
| invite__empty-submit | ![](img/10-8h/proto-invite__empty-submit-390.png) | ![](img/10-8h/flutter-invite__empty-submit-390.png) | ![](img/10-8h/proto-invite__empty-submit-1280.png) | ![](img/10-8h/flutter-invite__empty-submit-1280.png) |
| invitation-detail__pending | ![](img/10-8h/proto-invitation-detail__pending-390.png) | ![](img/10-8h/flutter-invitation-detail__pending-390.png) | ![](img/10-8h/proto-invitation-detail__pending-1280.png) | ![](img/10-8h/flutter-invitation-detail__pending-1280.png) |
| invitation-detail__expired | ![](img/10-8h/proto-invitation-detail__expired-390.png) | ![](img/10-8h/flutter-invitation-detail__expired-390.png) | ![](img/10-8h/proto-invitation-detail__expired-1280.png) | ![](img/10-8h/flutter-invitation-detail__expired-1280.png) |
| invitation-detail__revoke | ![](img/10-8h/proto-invitation-detail__revoke-390.png) | ![](img/10-8h/flutter-invitation-detail__revoke-390.png) | ![](img/10-8h/proto-invitation-detail__revoke-1280.png) | ![](img/10-8h/flutter-invitation-detail__revoke-1280.png) |
| member-detail__active | ![](img/10-8h/proto-member-detail__active-390.png) | ![](img/10-8h/flutter-member-detail__active-390.png) | ![](img/10-8h/proto-member-detail__active-1280.png) | ![](img/10-8h/flutter-member-detail__active-1280.png) |
| member-detail__suspended | ![](img/10-8h/proto-member-detail__suspended-390.png) | ![](img/10-8h/flutter-member-detail__suspended-390.png) | ![](img/10-8h/proto-member-detail__suspended-1280.png) | ![](img/10-8h/flutter-member-detail__suspended-1280.png) |
| member-detail__removed | ![](img/10-8h/proto-member-detail__removed-390.png) | ![](img/10-8h/flutter-member-detail__removed-390.png) | ![](img/10-8h/proto-member-detail__removed-1280.png) | ![](img/10-8h/flutter-member-detail__removed-1280.png) |
| member-detail__owner | ![](img/10-8h/proto-member-detail__owner-390.png) | ![](img/10-8h/flutter-member-detail__owner-390.png) | ![](img/10-8h/proto-member-detail__owner-1280.png) | ![](img/10-8h/flutter-member-detail__owner-1280.png) |
| member-detail__deactivate | ![](img/10-8h/proto-member-detail__deactivate-390.png) | ![](img/10-8h/flutter-member-detail__deactivate-390.png) | ![](img/10-8h/proto-member-detail__deactivate-1280.png) | ![](img/10-8h/flutter-member-detail__deactivate-1280.png) |
| select-role__default | ![](img/10-8h/proto-select-role__default-390.png) | ![](img/10-8h/flutter-select-role__default-390.png) | ![](img/10-8h/proto-select-role__default-1280.png) | ![](img/10-8h/flutter-select-role__default-1280.png) |
| select-role__selected | ![](img/10-8h/proto-select-role__selected-390.png) | ![](img/10-8h/flutter-select-role__selected-390.png) | ![](img/10-8h/proto-select-role__selected-1280.png) | ![](img/10-8h/flutter-select-role__selected-1280.png) |
| select-role__confirm | ![](img/10-8h/proto-select-role__confirm-390.png) | ![](img/10-8h/flutter-select-role__confirm-390.png) | ![](img/10-8h/proto-select-role__confirm-1280.png) | ![](img/10-8h/flutter-select-role__confirm-1280.png) |

Chỉ iPhone (proto | Flutter): ![](img/10-8h/proto-invitation-detail__actions-390.png) ![](img/10-8h/flutter-invitation-detail__actions-390.png) · ![](img/10-8h/proto-member-detail__actions-390.png) ![](img/10-8h/flutter-member-detail__actions-390.png) · ![](img/10-8h/proto-member-detail__actions-suspended-390.png) ![](img/10-8h/flutter-member-detail__actions-suspended-390.png)

## Code prototype (chép nguyên văn, token thay bằng giá trị)

### iPhone

`app/users.js:15-75`

```js
// ---------------------------------------------------------------- ID-14 danh sách
// Bố cục iPhone thiết kế lại qua impeccable live (2026-11-25); chữ giữ nguyên Flutter: tab hai nút liền → ô tìm + bộ lọc (nền trắng) → chip → thẻ; "Mời thành viên" ở thanh dưới (thay nút +).
const userLine = (ic, text) => `<span class="t1-ucard__line">${icon(ic)}${esc(text)}</span>`;
const userCard = (name, badges, lines, selected) => `<button type="button" class="t1-ucard"${selected ? ' aria-current="true"' : ''}><span class="t1-ucard__name"><b>${esc(name)}</b>${badges}</span>${lines.join('')}</button>`;
const memberCard = (m, selected) => userCard(m.name, `${m.isOwner ? badge('Chủ sở hữu', 'primary') : ''}<i></i>${badge(...MEMBER_BADGE[m.status])}`, [userLine('mail', m.email), userLine('shield', m.role)], selected);
/** Dòng phụ lời mời: vai trò; hạn · kết quả gửi (cùng chữ statusDetail). */
const invitationCard = (i, selected) => userCard(i.email, `<i></i>${badge(...INVITATION_BADGE[i.status])}`, [userLine('shield', i.role), userLine('clock', statusDetail(i).slice(i.role.length + 3))], selected);

/** UsersEmptyState trong UsersEmptyScroll (khung cao 480 canh giữa): VIconBox 56 bo 12 (icon 28) → 16 → H4 w700 → 8 → bodySmall → 24 → VButton. */
export const usersEmpty = ({ ic, tone = '', title, sub, action, danger = false, variant = 'primary' }) => `<div class="t1-uempty"><div class="t1-uempty__in">
  <span class="t1-ibox56${tone ? ` t1-ibox56--${tone}` : ''}">${icon(ic)}</span><div class="t1-gap-md"></div>
  <h2 class="t1-h4 t1-text-center${tone === 'danger' ? ' t1-danger' : ''}">${esc(title)}</h2><div class="t1-gap-sm"></div>
  <p class="t1-small t1-text-center">${esc(sub)}</p>${action ? `<div class="t1-gap-lg"></div>${button(action, { variant, cls: danger ? 't1-btn--danger' : '' })}` : ''}</div></div>`;

export const LIST_STATES = {
  members: { tab: 0 }, invitations: { tab: 1 }, loading: { tab: 0, loading: true }, 'invitations-loading': { tab: 1, loading: true },
  'invitations-empty': { tab: 1, empty: true }, 'no-results': { tab: 0, query: 'hoàng', empty: true }, 'chip-suspended': { tab: 0, chip: 'Tạm ngừng' },
  forbidden: { tab: 0, failure: 'forbidden' }, error: { tab: 0, failure: 'error' },
  'filter-members': { tab: 0, sheet: 'members' }, 'filter-invitations': { tab: 1, sheet: 'invitations' }, 'filter-applied': { tab: 0, filterOn: true, roleFilter: 'Kế toán' },
  'toast-revoked': { tab: 1, revoked: true, toast: ['success', 'Đã thu hồi lời mời.', ''] },
};

export function subtitle(s, items) {
  if (s.failure) return s.failure === 'forbidden' ? 'Chưa cấp quyền' : 'Không tải được';
  if (s.loading) return s.tab === 0 ? 'Đang tải thành viên' : 'Đang tải lời mời';
  if ((s.query || s.chip) && !items.length) return '0 kết quả';
  return s.tab === 0 ? `${items.length} thành viên` : `${items.length} lời mời`;
}

/** OrganizationUsersPage (VPageScaffold "Người dùng" + phụ đề) — placeWidth: 360 (cột trái web) hoặc bề ngang màn. */
export function usersListPage(s, placeWidth, { selectedId = null, toastHtml = '' } = {}) {
  let items = s.tab === 0 ? MEMBERS : INVITATIONS.filter((i) => !(s.revoked && i.id === 'i1'));
  if (s.chip === 'Tạm ngừng') items = items.filter((m) => m.status === 'suspended');
  if (s.roleFilter) items = items.filter((m) => m.role === s.roleFilter);
  if (s.empty) items = [];
  let list;
  if (s.loading) list = centerLoading();
  else if (s.failure === 'forbidden') list = usersEmpty({ ic: 'shield', tone: 'warning', title: 'Bạn không có quyền quản lý', sub: 'Liên hệ Chủ tổ chức hoặc Quản trị viên để được cấp quyền phù hợp.', action: 'Quay lại' });
  else if (s.failure) list = usersEmpty({ ic: 'close', tone: 'danger', title: 'Không thể tải danh sách', sub: 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra lại mạng.', action: 'Thử lại', danger: true });
  else if (!items.length && (s.query || s.chip)) list = usersEmpty({ ic: 'search', title: 'Không tìm thấy kết quả', sub: 'Thử từ khóa khác hoặc xóa bộ lọc đang áp dụng.', action: 'Xóa bộ lọc', variant: 'secondary' });
  else if (!items.length) list = usersEmpty({ ic: 'info', title: s.tab === 0 ? 'Chưa có thành viên khác' : 'Chưa có lời mời', sub: s.tab === 0 ? 'Mời thêm người dùng để cùng vận hành tổ chức.' : 'Mời thành viên mới để họ nhận email tham gia.', action: 'Mời thành viên' });
  else list = `<div class="t1-ulist">${items.map((x) => (s.tab === 0 ? memberCard(x, x.id === selectedId) : invitationCard(x, x.id === selectedId))).join('')}</div>`;
  const chips = s.tab === 0 ? ['Tất cả', 'Hoạt động', 'Tạm ngừng'] : ['Tất cả', 'Đang chờ', 'Hết hạn'];
  const body = `<div class="t1-utop"><div class="t1-useg" role="tablist">${['Thành viên', 'Lời mời'].map((l, i) => `<button type="button" role="tab" aria-selected="${i === s.tab}">${l}</button>`).join('')}</div>
      <div class="t1-utop__find">${searchBar('Tìm tên hoặc email', s.query || '')}${iconButton('tune', s.filterOn ? 'Bộ lọc (đang áp dụng)' : 'Bộ lọc', { size: 20, dot: !!s.filterOn })}</div></div>
    <div class="t1-chippad">${chipRow(chips, s.chip || 'Tất cả')}</div>
    <div class="t1-ulistwrap">${list}</div>`;
  // Một nút chính mỗi màn: ẩn thanh dưới khi khối rỗng / lỗi / không có quyền đã có nút riêng (không ra kết quả vẫn hiện, "Xóa bộ lọc" là secondary).
  const hasBar = !s.failure && (s.loading || items.length || s.query || s.chip);
  const bar = hasBar ? `<div class="t1-bar-pad">${button('Mời thành viên', { full: true, attrs: 'data-primary' })}</div>` : '';
  return vScaffold({ title: 'Người dùng', subtitle: subtitle(s, items), body, bottomBar: bar, placeWidth, fixed: true, toastHtml });
}

/** MemberFilterBottomSheet / InvitationFilterBottomSheet: đệm 16 / 16 / 16 / 24; tiêu đề nhóm bodyDefault w700, khe 4, Wrap chip khe 8; nhóm cách 16; khe 24; Đặt lại | khe 16 | Áp dụng. */
export function filterSheet(kind) {
  const groups = kind === 'members'
    ? [['Trạng thái', ['Tất cả', 'Hoạt động', 'Tạm ngừng']], ['Vai trò', ['Tất cả', 'Chủ cửa hàng', 'Nhân viên bán hàng', 'Kế toán', 'Thủ kho']], ['Sắp xếp', ['Tất cả', 'Tên A–Z', 'Tên Z–A']]]
    : [['Trạng thái', ['Tất cả', 'Đang chờ', 'Hết hạn']], ['Kết quả gửi', ['Tất cả', 'Đã gửi', 'Gửi lỗi', 'Thu hồi']], ['Thời gian', ['Tất cả', '7 ngày', '30 ngày', 'Tùy chọn']]];
  return `<div class="t1-fsheet">${groups.map(([t, opts]) => `<div class="t1-fgroup"><b>${esc(t)}</b><div class="t1-fwrap">${opts.map((o, i) => filterChip(o, i === 0)).join('')}</div></div>`).join('')}
    <div class="t1-row2 t1-fsheet__acts">${button('Đặt lại', { variant: 'secondary', full: true })}${button('Áp dụng', { full: true })}</div></div>`;
}
```

`app/users.js:105-127`

```js
export function invitePage(v) {
  const s = INVITE_STATES[v.state];
  const base = { title: 'Mời thành viên', placeWidth: v.width };
  if (s.loading) return { page: vScaffold({ ...base, body: centerLoading(), fixed: true }) };
  if (s.rolesFailed) return { page: vScaffold({ ...base, body: loadFailed('Không tải được danh sách vai trò', 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra lại mạng.'), fixed: true }) };
  const e = s.errors || {};
  // Bố cục iPhone thiết kế lại qua impeccable live (2026-11-25): thẻ Email (ghi chú dưới ô, giữ cả khi báo lỗi) → thẻ "Vai trò ban đầu" chọn bằng 4 dòng radio + mô tả → câu "có thể thay đổi sau".
  const roleRow = ([name, d]) => {
    const on = name === s.role;
    return `<button type="button" role="radio" class="t1-rolelist__opt${on ? ' is-on' : ''}" aria-checked="${on}">${radio(on)}<span><b>${esc(name)}</b><small>${esc(d)}</small></span></button>`;
  };
  const body = `<div class="t1-list t1-invitem">
    ${card(`${field({ label: 'Email', required: true, control: input({ value: s.email || '', hint: 'nhanvien@minhphat.vn', invalid: !!e.email }), error: e.email })}
      <p class="t1-small t1-invitem__note">Người nhận phải đăng nhập đúng email. Lời mời sẽ hết hạn sau 7 ngày.</p>`, 't1-card--pad')}
    ${card(`<div class="t1-rolelist__legend"><span class="t1-label">Vai trò ban đầu<i aria-hidden="true"> *</i></span></div>
      <div role="radiogroup" aria-label="Vai trò ban đầu">${SELECT_ROLES.map(roleRow).join('')}</div>`, `t1-rolelist${e.role ? ' is-invalid' : ''}`)}
    ${e.role ? `<div class="t1-invitem__error">${fieldError(e.role)}</div>` : ''}
    <p class="t1-small t1-invitem__later">Vai trò có thể thay đổi sau khi tham gia.</p>
  </div>`;
  // Nút gửi: khi đang gửi đổi chữ "Đang gửi..." + tắt (không có vòng xoay).
  const bar = `<div class="t1-bar-pad t1-row2 t1-row2--8">${button('Hủy', { variant: 'secondary', full: true, disabled: !!s.busy })}${button(s.busy ? 'Đang gửi...' : 'Gửi lời mời', { full: true, disabled: !!s.busy })}</div>`;
  return { page: vScaffold({ ...base, body, bottomBar: bar, toastHtml: s.toast ? toast(...s.toast, { device: v.device, above: BAR_H }) : '' }) };
}
```

`app/users.js:141-167`

```js
function invitationDetail(s, w, split, device) {
  const back = !split;
  const base = { title: 'Chi tiết lời mời', back, placeWidth: w };
  if (s.loading) return vScaffold({ ...base, body: centerLoading(), fixed: true });
  if (s.error) return vScaffold({ ...base, body: loadFailed('Không tải được lời mời', 'Không tìm thấy tài nguyên.'), fixed: true });
  const i = invitationById(s.id);
  const [label, tone] = INVITATION_BADGE[i.status];
  // Bố cục iPhone thiết kế lại qua impeccable live (2026-11-25): ô thư + email + hạn → thẻ "Thông tin lời mời" (vai trò, trạng thái, giao nhận); nhãn như bản web, không in giá trị wire.
  const delivery = statusDetail(i).split(' · ').pop();
  const body = `<div class="t1-list t1-orgm">
    <div class="t1-orgm__head"><div class="t1-orgm__icon" aria-hidden="true">${icon('mail')}</div><div><h2>${esc(i.email)}</h2><p>${esc(i.expiry)}</p></div></div>
    <section class="t1-card t1-card--pad t1-orgm__sec"><h3 class="t1-h4 t1-h4--600">Thông tin lời mời</h3>
      ${kv('Vai trò ban đầu', i.role, 't1-kv--profile')}<div class="t1-orgm__status"><span>Trạng thái</span>${badge(label, tone)}</div>${kv('Giao nhận', delivery, 't1-kv--profile')}</section>
  </div>`;
  const canMutate = i.wire === 'pending';
  const bar = canMutate ? `<div class="t1-bar-pad">${button('Thao tác', { full: true, trailing: 'chevronUp', loading: !!s.revokeBusy, attrs: 'data-primary' })}</div>` : '';
  return vScaffold({ ...base, body, bottomBar: bar, toastHtml: s.toast ? toast(...s.toast, { device, above: canMutate ? BAR_H : 0 }) : '' });
}

/** Sheet "Thao tác lời mời" (có title): đệm 16; IamActionTile gửi lại / khe 8 / thu hồi (danger) / khe 16. */
const invitationActions = () => `<div class="t1-list">${actionTile('rotate', 'Gửi lại lời mời', 'Gửi lại email đến người nhận')}<div class="t1-gap-sm"></div>${actionTile('trash', 'Thu hồi lời mời', 'Người nhận không thể tiếp tục tham gia', true)}<div class="t1-gap-md"></div></div>`;
/** _RevokeInvitationSheetBody: đệm 16; H3 w700 danger; khe 4; bodyDefault; (không khe) VField "Lý do thu hồi" + ô 3 dòng; khe 24; Quay lại / khe 8 / Thu hồi (secondary danger) / khe 8. */
export const revokeSheet = (s) => `<div class="t1-list"><h2 class="t1-h3 t1-danger">Thu hồi lời mời?</h2><div class="t1-gap-xs"></div>
  <p class="t1-body2">Người nhận sẽ không thể dùng liên kết hiện tại để tham gia tổ chức.</p>
  ${field({ label: 'Lý do thu hồi', control: textArea({ value: s.reason || '', hint: 'Ví dụ: Sai email người nhận', invalid: !!s.revokeError, disabled: !!s.revokeBusy }), error: s.revokeError })}
  <div class="t1-gap-lg"></div>${button('Quay lại', { variant: 'secondary', full: true, disabled: !!s.revokeBusy })}<div class="t1-gap-sm"></div>
  ${button('Thu hồi lời mời', { variant: 'secondary', full: true, loading: !!s.revokeBusy, cls: 't1-btn--danger-outline' })}<div class="t1-gap-sm"></div></div>`;
```

`app/users.js:189-237`

```js
/** _DetailRow (iPhone 2026-11-25): nhãn bodyDefault textSecondary ↔ giá trị bodyDefault w600 phải. */
const drow = (l, val) => kv(l, val, 't1-kv--profile');
/** Ô tròn 52: chữ đầu của tên; xám khi không còn hoạt động. */
const memberAvatar = (m) => `<span class="t1-orgm__avatar${m.status === 'active' ? '' : ' is-off'}" aria-hidden="true">${esc(m.name.trim().split(/\s+/).pop()[0])}</span>`;

function memberDetail(s, w, split, device) {
  const base = { title: 'Chi tiết thành viên', back: !split, placeWidth: w };
  if (s.loading) return vScaffold({ ...base, body: centerLoading(), fixed: true });
  if (s.error) return vScaffold({ ...base, body: loadFailed('Không tải được thành viên', 'Không tìm thấy tài nguyên.'), fixed: true });
  const m = memberById(s.id);
  const [label, tone] = MEMBER_BADGE[m.status];
  const access = m.status === 'active' ? drow('Ngày tham gia', m.joined) + drow('Hoạt động gần nhất', m.lastActive)
    : m.status === 'suspended' ? drow('Tạm ngừng lúc', m.suspendedAt) : drow('Đã loại lúc', m.removedAt) + drow('Vai trò trước đó', m.role);
  const note = m.status === 'suspended' ? banner('warning', 'Quyền truy cập đã tạm ngừng', 'Thành viên không thể truy cập tổ chức cho đến khi được kích hoạt lại.')
    : m.status === 'removed' ? banner('info', 'Thành viên đã được loại', 'Quyền truy cập đã kết thúc. Lịch sử và dữ liệu nghiệp vụ vẫn được giữ lại.') : '';
  // Bố cục iPhone thiết kế lại qua impeccable live (2026-11-25): ô tròn + tên + email → thẻ "Thông tin thành viên" (+ nhãn) → thông báo (tạm ngừng / đã loại) → thẻ "Trạng thái truy cập".
  const off = m.status === 'removed' ? ' t1-o60' : '';
  const body = `<div class="t1-list t1-orgm">
    <div class="t1-orgm__head${off}">${memberAvatar(m)}<div><h2>${esc(m.name)}</h2><p>${esc(m.email)}</p></div></div>
    <section class="t1-card t1-card--pad t1-orgm__sec${off}"><div class="t1-dhead"><h3 class="t1-h4 t1-h4--600">Thông tin thành viên</h3>${badge(label, tone)}</div>
      ${drow('Tên', m.name)}${drow('Email', m.email)}${drow('Vai trò hiện hành', m.role)}${drow(m.isOwner ? 'Quyền sở hữu' : 'Danh tính', m.isOwner ? 'Chủ sở hữu' : 'Chỉ đọc')}</section>
    ${note}
    <section class="t1-card t1-card--pad t1-orgm__sec"><h3 class="t1-h4 t1-h4--600">Trạng thái truy cập</h3>${access}</section>
  </div>`;
  const hasActions = !m.soleOwner && m.status !== 'removed';
  const bar = hasActions ? `<div class="t1-bar-pad">${button('Thao tác', { full: true, trailing: 'chevronUp', loading: !!s.busy, attrs: 'data-primary' })}</div>` : '';
  return vScaffold({ ...base, body, bottomBar: bar, toastHtml: s.toast ? toast(...s.toast, { device, above: hasActions ? BAR_H : 0 }) : '' });
}

/** showMemberLifecycleActionsBottomSheet: đệm 16 / 8 / 16 / 24; H3 w700 "Thao tác thành viên"; khe 16; tile cách 8. */
function memberActions(m) {
  const tiles = [actionTile('shield', 'Thay đổi vai trò', 'Cập nhật vai trò')];
  if (m.status === 'active') tiles.push(actionTile('pause', 'Tạm ngừng thành viên', 'Dừng quyền truy cập tạm thời'));
  if (m.status === 'suspended') tiles.push(actionTile('userCheck', 'Kích hoạt lại', 'Khôi phục quyền truy cập'));
  tiles.push(actionTile('userX', 'Loại khỏi tổ chức', 'Kết thúc tư cách thành viên', true));
  return `<div class="t1-sheetpad"><h2 class="t1-h3">Thao tác thành viên</h2><div class="t1-gap-md"></div>${tiles.join('<div class="t1-gap-sm"></div>')}</div>`;
}
/** MembershipLifecycleConfirmSheet: đệm 16 / 8 / 16 / 24; H3 w700 (danger tuỳ); khe 4; bodyDefault; khe 32; Quay lại / khe 8 / nút xác nhận. */
export const LIFECYCLE = {
  deactivate: { title: 'Tạm ngừng thành viên?', danger: true, desc: 'Thành viên mất quyền truy cập tới khi được kích hoạt lại.', ok: 'Tạm ngừng' },
  reactivate: { title: 'Kích hoạt lại thành viên?', danger: false, desc: 'Quyền truy cập sẽ được khôi phục theo vai trò hiện hành.', ok: 'Kích hoạt lại' },
  remove: { title: 'Loại thành viên khỏi tổ chức?', danger: true, desc: 'Thành viên sẽ kết thúc vĩnh viễn. Người này cần lời mời mới nếu quay lại.', ok: 'Loại thành viên' },
};
export const lifecycleSheet = (k, busy) => {
  const c = LIFECYCLE[k];
  return `<div class="t1-sheetpad"><h2 class="t1-h3${c.danger ? ' t1-danger' : ''}">${esc(c.title)}</h2><div class="t1-gap-xs"></div><p class="t1-body2">${esc(c.desc)}</p><div class="t1-gap-xl"></div>
    ${button('Quay lại', { variant: 'secondary', full: true, disabled: busy })}<div class="t1-gap-sm"></div>
    ${button(c.ok, { variant: c.danger ? 'secondary' : 'primary', full: true, loading: busy, cls: c.danger ? 't1-btn--danger-outline' : '' })}</div>`;
};
```

`app/users.js:248-272`

```js
// ---------------------------------------------------------------- ID-18 chọn vai trò
/** _availableRoles (mô tả riêng của màn này, ngắn hơn TH-01 3.4); vai trò hiện tại đưa lên đầu. */
export const SELECT_ROLES = [['Nhân viên bán hàng', 'Bán hàng và chăm sóc khách hàng'], ['Kế toán', 'Công nợ, hóa đơn và báo cáo'], ['Thủ kho', 'Nhập xuất, tồn kho và kiểm kê'], ['Chủ cửa hàng', 'Quản lý toàn bộ cửa hàng']];
export const SELECT_STATES = { default: { id: 'm2' }, selected: { id: 'm2', pick: 'Thủ kho' }, suspended: { id: 'm3' } };

// Bố cục iPhone thiết kế lại qua impeccable live (2026-11-25): ô tròn + tên + nhãn → "Chọn vai trò mới" → thẻ danh sách (vai trò hiện tại dòng đầu nền canvas, không chọn được). Web giữ bản cũ ở web/users.js.
function selectRole(s, w) {
  const m = memberById(s.id);
  const i = SELECT_ROLES.findIndex(([t]) => t === m.role);
  const roles = i > 0 ? [SELECT_ROLES[i], ...SELECT_ROLES.filter((_, k) => k !== i)] : SELECT_ROLES;
  const active = m.status === 'active';
  const item = ([t, d]) => {
    const text = `<span class="t1-rolelist__text"><b>${esc(t)}</b><small>${esc(d)}</small></span>`;
    if (t === m.role) return `<div class="t1-rolelist__opt is-current">${text}${badge('Hiện tại', 'success')}</div>`;
    const on = t === s.pick;
    return `<button type="button" role="radio" class="t1-rolelist__opt${on ? ' is-on' : ''}" aria-checked="${on}">${radio(on)}${text}</button>`;
  };
  const body = `<div class="t1-list t1-selrole">
    <div class="t1-orgm__head">${memberAvatar(m)}<div><div class="t1-selrole__name"><h2>${esc(m.name)}</h2>${badge(active ? 'Hoạt động' : 'Tạm ngừng', active ? 'success' : 'danger')}</div>
      <p>${esc(`${m.email} · ${m.role}`)}</p><p>${m.isOwner ? 'Quyền sở hữu: Chủ sở hữu' : 'Danh tính: Chỉ đọc'}</p></div></div>
    <h3 class="t1-selrole__title">Chọn vai trò mới</h3><p class="t1-small t1-selrole__sub">Mỗi thành viên có đúng một vai trò hiện hành.</p>
    ${card(`<div role="radiogroup" aria-label="Chọn vai trò mới">${roles.map(item).join('')}</div>`, 't1-rolelist')}</div>`;
  const bar = `<div class="t1-bar-pad t1-row2 t1-row2--8">${button('Hủy', { variant: 'secondary', full: true })}${button('Tiếp tục', { full: true, disabled: !s.pick, attrs: 'data-primary' })}</div>`;
  return vScaffold({ title: 'Chọn vai trò', body, bottomBar: bar, placeWidth: w });
}
```

`styles/t1.css:265-305`

```css
/* ------------------------------------------------ Người dùng (iPhone, impeccable live 2026-11-25; web ở t1-web.css) */
.t1-utop { flex: 0 0 auto; background: #FFFFFF /*surface-default*/; border-bottom: 1px solid #E5E8EB /*border-default*/; }
.t1-utop__find { display: flex; align-items: center; gap: 4px; padding: 12px 8px 12px 16px; }
.t1-utop__find .t1-vsearch { flex: 1; min-width: 0; }
.t1-useg { display: grid; grid-template-columns: 1fr 1fr; margin: 12px 16px 0; padding: 3px; border-radius: 8px /*radius-3*/; background: #F1F3F5 /*neutral-150*/; }
.t1-useg button { min-height: 40px; border: 0; border-radius: 6px /*radius-2*/; background: transparent; font-size: 14px /*fs-md*/; line-height: 20px; font-weight: 600; color: #4A535E /*text-secondary*/; cursor: pointer; }
.t1-useg button[aria-selected="true"] { background: #FFFFFF /*surface-default*/; color: #26612F /*text-brand*/; box-shadow: 0 2px 8px rgba(14, 17, 22, 0.04) /*shadow-1*/; }
.t1-ucard { display: flex; flex-direction: column; gap: 4px; width: 100%; padding: 12px 16px; border: 1px solid #D0D5DA /*border-strong*/; border-radius: 12px /*radius-card*/; background: #FFFFFF /*surface-default*/; text-align: left; color: #0E1116 /*text-primary*/; cursor: pointer; }
.t1-ucard:hover { background: #F8FAFB /*neutral-50*/; }
.t1-ucard__name { display: flex; flex-wrap: wrap; align-items: center; gap: 2px 8px; }
.t1-ucard__name b { min-width: 0; overflow-wrap: anywhere; font-size: 14px /*fs-md*/; line-height: 22px; font-weight: 600; }
.t1-ucard__name i { flex: 1; }
.t1-ucard__line { display: flex; align-items: flex-start; gap: 8px; overflow-wrap: anywhere; font-size: 13px /*fs-sm*/; line-height: 20px; font-weight: 500; color: #4A535E /*text-secondary*/; }
.t1-ucard__line .icon { flex: none; margin-top: 2px; font-size: 16px; color: #6B7480 /*icon-secondary*/; }

/* ------------------------------------------------ Mời thành viên (iPhone, impeccable live 2026-11-25; web ở t1-web.css) */
.t1-invitem { display: flex; flex-direction: column; gap: 12px; }
.t1-invitem__note { margin-top: 8px; }
.t1-invitem__error { display: flex; margin-top: -12px; padding: 0 2px; }
.t1-invitem__later { margin-top: -4px; padding: 0 2px; }
.t1-rolelist { overflow: hidden; }
.t1-rolelist.is-invalid { border-color: #B53232 /*text-danger*/; }
.t1-rolelist__legend { padding: 16px 16px 4px; }
.t1-rolelist__legend .t1-label { margin: 0; }
.t1-rolelist__opt { display: flex; align-items: center; gap: 12px; width: 100%; min-height: 60px; padding: 8px 16px; border: 0; background: transparent; text-align: left; color: #0E1116 /*text-primary*/; cursor: pointer; }
.t1-rolelist__opt + .t1-rolelist__opt { border-top: 1px solid #E5E8EB /*border-default*/; }
.t1-rolelist__opt.is-on { background: #EBF4EE /*surface-brand*/; }
.t1-rolelist__opt:focus-visible { outline-offset: -2px; }
.t1-rolelist__opt .t1-radio-hit { flex: 0 0 20px; width: 20px; height: 20px; margin: 0; }
.t1-rolelist__opt b { display: block; font-size: 14px /*fs-md*/; line-height: 22px; font-weight: 600; }
.t1-rolelist__opt small { display: block; font-size: 13px /*fs-sm*/; line-height: 20px; font-weight: 500; color: #4A535E /*text-secondary*/; }

/* ------------------------------------------------ Chọn vai trò (iPhone, impeccable live 2026-11-25; web dùng .t1-roleopt) */
.t1-selrole .t1-orgm__head { padding-bottom: 20px; }
.t1-selrole .t1-orgm__head p { font-size: 13px /*fs-sm*/; line-height: 20px; overflow-wrap: anywhere; }
.t1-selrole__name { display: flex; flex-wrap: wrap; align-items: center; gap: 2px 8px; }
.t1-selrole__title { margin: 0; font-size: 18px /*fs-h3*/; line-height: 26px; font-weight: 700; letter-spacing: -0.2px; color: #0E1116 /*text-primary*/; }
.t1-selrole__sub { margin: 2px 0 12px; }
.t1-rolelist__text { flex: 1; min-width: 0; }
.t1-rolelist__opt.is-current { background: #F6F8F9 /*surface-canvas*/; cursor: default; }
.t1-rolelist__opt.is-current + .t1-rolelist__opt { border-top: 1px solid #E5E8EB /*border-default*/; }
```

`styles/t1.css:601-625`

```css
.t1-ring--56 { width: 56px; height: 56px; }

/* ID-14…18 */
.t1-chippad { flex: 0 0 auto; padding: 12px 16px; }
.t1-ulistwrap { flex: 1; min-height: 0; overflow-y: auto; display: flex; flex-direction: column; }
.t1-ulist { display: flex; flex-direction: column; gap: 8px; padding: 8px 16px 32px; }
.t1-urow { display: flex; align-items: center; gap: 8px; }
.t1-urow__ic { flex: 0 0 auto; margin-right: 8px; font-size: 24px; color: #0E1116 /*text-primary*/; }
.t1-urow__text { flex: 1; min-width: 0; display: flex; flex-direction: column; gap: 4px; }
.t1-urow__text b { font-size: 14px /*fs-md*/; line-height: 22px; font-weight: 700; color: #0E1116 /*text-primary*/; }
.t1-urow__text > span { font-size: 13px /*fs-sm*/; line-height: 20px; font-weight: 500; color: #4A535E /*text-secondary*/; }
.t1-urow__name { display: flex; flex-wrap: wrap; align-items: center; gap: 4px 8px; }
.t1-uempty { flex: 0 0 480px; display: grid; place-items: center; }
.t1-uempty__in { display: flex; flex-direction: column; align-items: center; padding: 16px; }
.t1-ibox56 { display: grid; place-items: center; width: 56px; height: 56px; border-radius: 12px; background: #F6F8F9 /*surface-canvas*/; color: #0E1116 /*text-primary*/; font-size: 28px; }
.t1-ibox56--warning { background: #F9F1E2 /*surface-warning*/; color: #935A0A /*text-warning*/; }
.t1-ibox56--danger { background: #F8ECEC /*surface-danger*/; color: #B53232 /*text-danger*/; }
.t1-fsheet { padding: 16px 16px 24px; }
.t1-fgroup b { display: block; margin-bottom: 4px; font-size: 14px /*fs-md*/; line-height: 22px; font-weight: 700; color: #0E1116 /*text-primary*/; }
.t1-fgroup--8 b { margin-bottom: 8px; }
.t1-fgroup + .t1-fgroup { margin-top: 16px; }
.t1-fwrap { display: flex; flex-wrap: wrap; gap: 8px; }
.t1-fsheet__acts { margin-top: 24px; }
.t1-dhead { display: flex; align-items: center; justify-content: space-between; gap: 8px; }
.t1-dhead > h2, .t1-dhead > b { flex: 1; min-width: 0; }
```


### Web

`app/web/users.js:14-178`

```js
/** Chữ viết tắt: ký tự đầu của tên (từ cuối họ tên). */
const initial = (name) => esc(String(name).trim().split(/\s+/).pop()[0] || '');

const avatar = (name) => `<span class="t1-avatar" aria-hidden="true">${initial(name)}</span>`;

/** Đang tải (VSkeletonScope): 4 dòng bảng giả dưới hàng tiêu đề thật. */
const tableSkeleton = (cols) => `<div class="t1-utable" role="table" aria-busy="true" aria-label="Đang tải"><div class="t1-utable__tr t1-utable__th" role="row">${cols.map((c) => `<span role="columnheader">${esc(c)}</span>`).join('')}<span></span></div>
  ${[0, 1, 2, 3].map(() => `<div class="t1-utable__tr t1-utable__tr--skel"><span class="t1-utable__who">${skeleton({ w: 36, h: 36, circle: true })}<span class="t1-skelcol">${skeleton({ w: 160, h: 16 })}${skeleton({ w: 120, h: 12 })}</span></span><span>${skeleton({ w: 120 })}</span><span>${skeleton({ w: 72, h: 22 })}</span><span>${cols[3] ? skeleton({ w: 110 }) : ''}</span><span></span></div>`).join('')}</div>`;

/** Lọc danh sách theo trạng thái mẫu, chọn khối rỗng / lỗi, rồi vẽ bảng toàn màn. */
function usersListPage(s, toastHtml) {
  let items = s.tab === 0 ? MEMBERS : INVITATIONS.filter((i) => !(s.revoked && i.id === 'i1'));
  if (s.chip === 'Tạm ngừng') items = items.filter((m) => m.status === 'suspended');
  if (s.roleFilter) items = items.filter((m) => m.role === s.roleFilter);
  if (s.empty) items = [];
  let list = ''; // khối rỗng / lỗi; '' = có dữ liệu, null = đang tải
  if (s.loading) list = null;
  else if (s.failure === 'forbidden') list = usersEmpty({ ic: 'shield', tone: 'warning', title: 'Bạn không có quyền quản lý', sub: 'Liên hệ Chủ tổ chức hoặc Quản trị viên để được cấp quyền phù hợp.', action: 'Quay lại' });
  else if (s.failure) list = usersEmpty({ ic: 'close', tone: 'danger', title: 'Không thể tải danh sách', sub: 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra lại mạng.', action: 'Thử lại', danger: true });
  else if (!items.length && (s.query || s.chip)) list = usersEmpty({ ic: 'search', title: 'Không tìm thấy kết quả', sub: 'Thử từ khóa khác hoặc xóa bộ lọc đang áp dụng.', action: 'Xóa bộ lọc' });
  else if (!items.length) list = usersEmpty({ ic: 'info', title: s.tab === 0 ? 'Chưa có thành viên khác' : 'Chưa có lời mời', sub: s.tab === 0 ? 'Mời thêm người dùng để cùng vận hành tổ chức.' : 'Mời thành viên mới để họ nhận email tham gia.', action: 'Mời thành viên' });
  const chips = s.tab === 0 ? ['Tất cả', 'Hoạt động', 'Tạm ngừng'] : ['Tất cả', 'Đang chờ', 'Hết hạn'];
  return usersTablePage(s, items, list, chips, toastHtml);
}

/**
 * Web (≥ 840) — bảng toàn màn, chọn qua impeccable live (2026-11-24): app bar "Người dùng" + phụ đề + nút "Mời thành viên";
 * thanh công cụ (tab trái, ô tìm + bộ lọc phải); cột 1120: chip nhanh → bảng. Bấm dòng mở chi tiết toàn màn (nút ←).
 * Trạng thái rỗng / lỗi / đang tải dùng lại khối của danh sách hẹp, đặt vào chỗ bảng.
 */
function usersTable(s, items) {
  const head = (cols) => `<div class="t1-utable__tr t1-utable__th" role="row">${cols.map((c) => `<span role="columnheader">${esc(c)}</span>`).join('')}<span></span></div>`;
  const chev = icon('chevronRight', 't1-utable__chev');
  if (s.tab === 0) {
    return `<div class="t1-utable" role="table" aria-label="Thành viên">${head(['Tên', 'Vai trò hiện hành', 'Trạng thái truy cập', 'Hoạt động gần nhất'])}
      ${items.map((m) => `<button type="button" class="t1-utable__tr" role="row"><span class="t1-utable__who">${avatar(m.name)}<span><b>${esc(m.name)}</b>${m.isOwner ? badge('Chủ sở hữu', 'primary') : ''}<small>${esc(m.email)}</small></span></span><span>${esc(m.role)}</span><span>${badge(...MEMBER_BADGE[m.status])}</span><span class="t1-utable__num">${esc(m.status === 'active' ? m.lastActive : '—')}</span>${chev}</button>`).join('')}</div>`;
  }
  return `<div class="t1-utable" role="table" aria-label="Lời mời">${head(['Email', 'Vai trò ban đầu', 'Trạng thái', ''])}
    ${items.map((i) => `<button type="button" class="t1-utable__tr" role="row"><span class="t1-utable__who">${avatar(i.email.split('@')[0])}<span><b>${esc(i.email)}</b><small>${esc(i.expiry)} · ${esc(statusDetail(i).split(' · ').pop())}</small></span></span><span>${esc(i.role)}</span><span>${badge(...INVITATION_BADGE[i.status])}</span><span></span>${chev}</button>`).join('')}</div>`;
}

function usersTablePage(s, items, state, chips, toastHtml) {
  const cols = s.tab === 0 ? ['Tên', 'Vai trò hiện hành', 'Trạng thái truy cập', 'Hoạt động gần nhất'] : ['Email', 'Vai trò ban đầu', 'Trạng thái', ''];
  const content = s.loading ? tableSkeleton(cols) : state ? `<div class="t1-utable t1-utable--state">${state}</div>` : usersTable(s, items);
  const bar = `<div class="t1-utools"><div class="t1-utools__tabs">${tabs(['Thành viên', 'Lời mời'], s.tab)}</div>
    <div class="t1-utools__find">${searchBar('Tìm tên hoặc email', s.query || '')}${iconButton('tune', s.filterOn ? 'Bộ lọc (đang áp dụng)' : 'Bộ lọc', { size: 20, dot: !!s.filterOn })}</div></div>`;
  return `<div class="t1-page t1-page--canvas">${appBar('Người dùng', { back: true, subtitle: subtitle(s, items), actions: `<div class="t1-uinvite">${button('Mời thành viên')}</div>` })}
    ${bar}<div class="t1-scroll"><div class="t1-uwrap"><div class="t1-uwrap__chips">${chipRow(chips, s.chip || 'Tất cả')}</div>${content}</div></div>${toastHtml}</div>`;
}

export function usersPage(v) {
  const s = LIST_STATES[v.state];
  const t = s.toast ? toast(...s.toast, { device: v.device }) : '';
  // Thu hồi xong quay về danh sách → toast đáy màn (web).
  const page = usersListPage(s, t);
  const overlay = s.sheet ? adaptiveSheet(v.width, filterSheet(s.sheet), '', { title: s.sheet === 'members' ? 'Bộ lọc thành viên' : 'Bộ lọc lời mời' }) : '';
  return { page, overlay };
}

export function invitePage(v) {
  const s = INVITE_STATES[v.state];
  const base = { title: 'Mời thành viên', placeWidth: v.width };
  if (s.loading) return { page: vScaffold({ ...base, body: centerLoading(), fixed: true }) };
  if (s.rolesFailed) return { page: vScaffold({ ...base, body: loadFailed('Không tải được danh sách vai trò', 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra lại mạng.'), fixed: true }) };
  const e = s.errors || {};
  // Câu dẫn → thẻ trắng: Email → "Vai trò ban đầu" chọn bằng 4 thẻ có radio + mô tả (2 cột ≥ 600). Chọn qua impeccable live (2026-11-24).
  const roleCard = ([t, d]) => {
    const on = t === s.role;
    return `<button type="button" class="t1-rolepick__opt${on ? ' is-on' : ''}" aria-pressed="${on}"${s.busy ? ' disabled' : ''}>${radio(on)}<span><b>${esc(t)}</b><small>${esc(d)}</small></span></button>`;
  };
  const body = `<div class="t1-formpage"><p class="t1-small">Người nhận phải đăng nhập đúng email. Lời mời sẽ hết hạn sau 7 ngày.</p>
    <div class="t1-formcard"><div class="t1-form">
      ${field({ label: 'Email', required: true, control: input({ value: s.email || '', hint: 'nhanvien@minhphat.vn', invalid: !!e.email, disabled: !!s.busy }), error: e.email })}
      <fieldset class="t1-rolepick${e.role ? ' is-invalid' : ''}"><legend class="t1-label">Vai trò ban đầu<i aria-hidden="true"> *</i></legend>
        <div class="t1-rolepick__grid">${SELECT_ROLES.map(roleCard).join('')}</div>
        ${e.role ? fieldError(e.role) : fieldDesc('Vai trò có thể thay đổi sau khi tham gia.')}</fieldset>
    </div></div></div>`;
  // Nút gửi: khi đang gửi đổi chữ "Đang gửi..." + tắt (không có vòng xoay).
  const bar = `<div class="t1-bar-pad t1-row2 t1-row2--8">${button('Hủy', { variant: 'secondary', full: true, disabled: !!s.busy })}${button(s.busy ? 'Đang gửi...' : 'Gửi lời mời', { full: true, disabled: !!s.busy })}</div>`;
  return { page: vScaffold({ ...base, body, bottomBar: bar, toastHtml: s.toast ? toast(...s.toast, { device: v.device, above: BAR_H }) : '' }) };
}

function invitationDetail(s, w, device) {
  const base = { title: 'Chi tiết lời mời', placeWidth: w };
  if (s.loading) return vScaffold({ ...base, body: centerLoading(), fixed: true });
  if (s.error) return vScaffold({ ...base, body: loadFailed('Không tải được lời mời', 'Không tìm thấy tài nguyên.'), fixed: true });
  const i = invitationById(s.id);
  const [label, tone] = INVITATION_BADGE[i.status];
  // Thiết kế lại qua impeccable live (2026-11-24): đầu trang (chữ viết tắt + email + hạn) → khối "Thông tin lời mời" (nhãn trạng thái,
  // 3 dòng nhãn | giá trị) → còn chờ: "Gửi lại lời mời" + "Thu hồi lời mời" ngay cuối khối (không còn thanh "Thao tác" / sheet).
  const delivery = statusDetail(i).split(' · ').pop();
  const canMutate = i.wire === 'pending';
  const acts = canMutate ? `<div class="t1-invacts">${button('Gửi lại lời mời', { variant: 'secondary' })}${button('Thu hồi lời mời', { variant: 'secondary', cls: 't1-btn--danger-outline', loading: !!s.revokeBusy })}</div>` : '';
  const body = `<div class="t1-orgp">
    <div class="t1-orgp__head">${avatar(i.email.split('@')[0]).replace('t1-avatar"', 't1-avatar t1-avatar--lg"')}<div><h1>${esc(i.email)}</h1><p>${esc(i.expiry)}</p></div></div>
    <section class="t1-orgsec"><div class="t1-orgsec__head"><h2>Thông tin lời mời</h2>${badge(label, tone)}</div>
      <div class="t1-stack12">${kv('Vai trò ban đầu', i.role, 't1-kv--profile')}${kv('Trạng thái', label, 't1-kv--profile')}${kv('Giao nhận', delivery, 't1-kv--profile')}</div>
      ${acts}</section>
  </div>`;
  return vScaffold({ ...base, body, toastHtml: s.toast ? toast(...s.toast, { device, above: 0 }) : '' });
}

export function invitationDetailPage(v) {
  const s = INVITATION_STATES[v.state];
  const page = invitationDetail(s, v.width, v.device);
  let overlay = '';
  if (s.sheet === 'revoke') overlay = adaptiveSheet(v.width, revokeSheet(s), 'Thu hồi lời mời?');
  return { page, overlay };
}

function memberDetail(s, w, device) {
  const base = { title: 'Chi tiết thành viên', placeWidth: w };
  if (s.loading) return vScaffold({ ...base, body: centerLoading(), fixed: true });
  if (s.error) return vScaffold({ ...base, body: loadFailed('Không tải được thành viên', 'Không tìm thấy tài nguyên.'), fixed: true });
  const m = memberById(s.id);
  const [label, tone] = MEMBER_BADGE[m.status];
  // Thiết kế lại qua impeccable live (2026-11-24): đầu trang (chữ viết tắt + tên + email · vai trò) → khối "Thông tin thành viên" (+ nhãn)
  // → ghi chú (tạm ngừng / đã loại) → khối "Trạng thái truy cập" + nút thao tác ngay cuối khối (không còn thanh "Thao tác" / sheet).
  const row = (l, val) => kv(l, val, 't1-kv--profile');
  const access = m.status === 'active' ? row('Ngày tham gia', m.joined) + row('Hoạt động gần nhất', m.lastActive)
    : m.status === 'suspended' ? row('Tạm ngừng lúc', m.suspendedAt) : row('Đã loại lúc', m.removedAt) + row('Vai trò trước đó', m.role);
  const note = m.status === 'suspended' ? banner('warning', 'Quyền truy cập đã tạm ngừng', 'Thành viên không thể truy cập tổ chức cho đến khi được kích hoạt lại.')
    : m.status === 'removed' ? banner('info', 'Thành viên đã được loại', 'Quyền truy cập đã kết thúc. Lịch sử và dữ liệu nghiệp vụ vẫn được giữ lại.') : '';
  const hasActions = !m.soleOwner && m.status !== 'removed';
  const acts = hasActions ? `<div class="t1-invacts">${button('Thay đổi vai trò', { variant: 'secondary' })}${m.status === 'active' ? button('Tạm ngừng thành viên', { variant: 'secondary' }) : button('Kích hoạt lại', { variant: 'secondary' })}${button('Loại khỏi tổ chức', { variant: 'secondary', cls: 't1-btn--danger-outline' })}</div>` : '';
  const sec = (title, action, inner) => `<section class="t1-orgsec"><div class="t1-orgsec__head"><h2>${esc(title)}</h2>${action}</div>${inner}</section>`;
  const body = `<div class="t1-orgp">
    <div class="t1-orgp__head${m.status === 'removed' ? ' t1-o60' : ''}">${avatar(m.name).replace('t1-avatar"', 't1-avatar t1-avatar--lg"')}<div><h1>${esc(m.name)}</h1><p>${esc(`${m.email} · ${m.role}`)}</p></div></div>
    <div${m.status === 'removed' ? ' class="t1-o60"' : ''}>${sec('Thông tin thành viên', badge(label, tone), `<div class="t1-stack12">${row('Tên', m.name)}${row('Email', m.email)}${row('Vai trò hiện hành', m.role)}${row(m.isOwner ? 'Quyền sở hữu' : 'Danh tính', m.isOwner ? 'Chủ sở hữu' : 'Chỉ đọc')}</div>`)}</div>
    ${note}
    ${sec('Trạng thái truy cập', '', `<div class="t1-stack12">${access}</div>${acts}`)}
  </div>`;
  return vScaffold({ ...base, body, toastHtml: s.toast ? toast(...s.toast, { device, above: 0 }) : '' });
}

export function memberDetailPage(v) {
  const s = MEMBER_STATES[v.state];
  const page = memberDetail(s, v.width, v.device);
  let overlay = '';
  if (LIFECYCLE[s.sheet]) overlay = adaptiveSheet(v.width, lifecycleSheet(s.sheet, !!s.busy), LIFECYCLE[s.sheet].title);
  return { page, overlay };
}

function selectRole(s, w) {
  const m = memberById(s.id);
  const i = SELECT_ROLES.findIndex(([t]) => t === m.role);
  const roles = i > 0 ? [SELECT_ROLES[i], ...SELECT_ROLES.filter((_, k) => k !== i)] : SELECT_ROLES;
  const active = m.status === 'active';
  const item = ([t, d]) => {
    const cur = t === m.role; const on = t === s.pick;
    return `<div class="t1-roleopt${on ? ' is-on' : ''}">${icon('user', 't1-roleopt__ic')}<div class="t1-roleopt__text"><b>${esc(t)}</b><span>${esc(d)}</span></div>${cur ? badge('Hiện tại', 'success') : radio(on)}</div>`;
  };
  const body = `<div class="t1-list">
    ${vcard(`<div class="t1-dhead"><h2 class="t1-h4">${esc(m.name)}</h2>${badge(active ? 'Hoạt động' : 'Tạm ngừng', active ? 'success' : 'danger')}</div><div class="t1-gap-xs"></div>
      <p class="t1-small">${esc(`${m.email} · ${m.role}`)}</p><div class="t1-gap-md"></div><p class="t1-strong">${m.isOwner ? 'Quyền sở hữu: Chủ sở hữu' : 'Danh tính: Chỉ đọc'}</p>`)}
    <div class="t1-gap-md"></div><h2 class="t1-h4">Chọn vai trò mới</h2><div class="t1-gap-xs"></div><p class="t1-small">Mỗi thành viên có đúng một vai trò hiện hành.</p><div class="t1-gap-md"></div>
    ${roles.map(item).join('')}</div>`;
  const bar = `<div class="t1-bar-pad t1-row2 t1-row2--8">${button('Hủy', { variant: 'secondary', full: true })}${button('Tiếp tục', { full: true, disabled: !s.pick })}</div>`;
  return vScaffold({ title: 'Chọn vai trò', body, bottomBar: bar, placeWidth: w });
}

export function selectRolePage(v) {
  const s = SELECT_STATES[v.state];
  return { page: selectRole(s, v.width) };
}
```

`styles/t1-web.css:90-144`

```css
/* Người dùng — web (≥ 840): bảng toàn màn. Chữ viết tắt đầu tên dùng chung cả danh sách hẹp. */
.t1-avatar { display: grid; place-items: center; flex: none; width: 36px; height: 36px; border-radius: 999px /*radius-pill*/; background: #EBF4EE /*surface-brand*/; color: #26612F /*primary-700*/; font-size: 14px /*fs-md*/; font-weight: 700; text-transform: uppercase; }
.t1-uinvite { margin-right: 12px; }
.t1-uinvite .t1-btn { height: 40px; min-height: 40px; }
.t1-utools { flex: 0 0 auto; display: flex; align-items: center; justify-content: space-between; gap: 16px; padding: 0 24px; background: #FFFFFF /*surface-default*/; border-bottom: 1px solid #E5E8EB /*border-default*/; }
.t1-utools__tabs .t1-tabs { border-bottom: 0; }
.t1-utools__tabs .t1-tab { flex: none; padding: 14px 16px 12px; }
.t1-utools__find { display: flex; align-items: center; gap: 8px; width: 360px; }
.t1-utools__find .t1-vsearch { flex: 1; }
.t1-uwrap { width: 100%; max-width: 1120px; margin: 0 auto; padding: 20px 24px 32px; }
.t1-uwrap__chips { margin-bottom: 16px; }
.t1-utable { border: 1px solid #E5E8EB /*border-default*/; border-radius: 12px /*radius-card*/; background: #FFFFFF /*surface-default*/; overflow: hidden; }
.t1-utable--state { display: flex; flex-direction: column; min-height: 360px; }
.t1-utable--state > .t1-uempty { flex: 1 0 360px; }
.t1-utable__tr { display: grid; grid-template-columns: minmax(260px, 2fr) 1.2fr 1fr 1fr 24px; align-items: center; gap: 16px; width: 100%; padding: 12px 20px; border: 0; border-top: 1px solid #E5E8EB /*border-default*/; background: transparent; font: inherit; font-size: 14px /*fs-md*/; color: #0E1116 /*text-primary*/; text-align: left; cursor: pointer; }
.t1-utable__tr:hover { background: #F8FAFB /*neutral-50*/; }
.t1-utable__tr:focus-visible { outline: 2px solid #2F7A3A /*focus-ring*/; outline-offset: -2px; }
.t1-utable__th { border-top: 0; background: #F6F8F9 /*surface-canvas*/; font-size: 12px /*fs-xs*/; font-weight: 600; color: #4A535E /*text-secondary*/; cursor: default; }
.t1-utable__th:hover { background: #F6F8F9 /*surface-canvas*/; }
.t1-utable__who { display: flex; align-items: center; gap: 12px; min-width: 0; }
.t1-utable__who > span:last-child { display: flex; flex-wrap: wrap; align-items: center; column-gap: 8px; min-width: 0; }
.t1-utable__who b { font-weight: 600; }
.t1-utable__who small { flex-basis: 100%; font-size: 13px /*fs-sm*/; color: #4A535E /*text-secondary*/; }
.t1-utable__num { font-variant-numeric: tabular-nums; color: #4A535E /*text-secondary*/; }
.t1-utable__chev { width: 20px; height: 20px; color: #9AA3AD /*icon-muted*/; }

/* VSkeleton: nền surfaceAlt (neutral-100), bo 4, nhấp nháy độ mờ 0.4 ↔ 0.8 / 1 s easeInOut; giảm chuyển động → 0.5 đứng yên. */
.t1-skel { display: block; flex: none; max-width: 100%; border-radius: 4px; background: #F6F8F9 /*neutral-100*/; animation: t1-skel-pulse 1s ease-in-out infinite alternate; }
.t1-skel--circle { border-radius: 999px /*radius-pill*/; }
.t1-skelcol { display: flex; flex-direction: column; align-items: flex-start; gap: 8px; }
.t1-utable__who > .t1-skelcol { flex-wrap: nowrap; align-items: flex-start; }
.t1-utable__tr--skel { cursor: default; }
.t1-utable__tr--skel:hover { background: transparent; }
@keyframes t1-skel-pulse { from { opacity: .4; } to { opacity: .8; } }
@media (prefers-reduced-motion: reduce) { .t1-skel { animation: none; opacity: .5; } }

/* Mời thành viên: chọn vai trò bằng thẻ (radio + tên + mô tả), 2 cột từ 600; thẻ chọn nền surfaceBrand + viền primary. */
.t1-rolepick { min-width: 0; margin: 0; padding: 0; border: 0; }
.t1-rolepick > legend { padding: 0; margin-bottom: 8px; }
.t1-rolepick__grid { display: grid; grid-template-columns: 1fr; gap: 8px; }
@media (min-width: 600px) { .t1-rolepick__grid { grid-template-columns: 1fr 1fr; } }
.t1-rolepick__opt { display: flex; align-items: flex-start; gap: 12px; padding: 12px 16px; border: 1px solid #D0D5DA /*border-strong*/; border-radius: 8px /*radius-3*/; background: #FFFFFF /*surface-default*/; font: inherit; text-align: left; cursor: pointer; }
.t1-rolepick__opt:hover:not(:disabled) { border-color: #BDD9C2 /*border-brand*/; }
.t1-rolepick__opt:focus-visible { outline: 2px solid #2F7A3A /*focus-ring*/; outline-offset: 2px; }
.t1-rolepick__opt:disabled { cursor: default; opacity: .6; }
.t1-rolepick__opt.is-on { border-color: #2F7A3A /*action-primary-default*/; background: #EBF4EE /*surface-brand*/; }
.t1-rolepick.is-invalid .t1-rolepick__opt:not(.is-on) { border-color: #B53232 /*border-danger*/; }
.t1-rolepick__opt > span { display: flex; flex-direction: column; gap: 2px; min-width: 0; }
.t1-rolepick__opt b { font-size: 14px /*fs-md*/; line-height: 20px; font-weight: 600; color: #0E1116 /*text-primary*/; }
.t1-rolepick__opt small { font-size: 13px /*fs-sm*/; line-height: 18px; color: #4A535E /*text-secondary*/; }
.t1-rolepick .t1-error, .t1-rolepick .t1-desc { display: block; }
.t1-rolepick__opt > .t1-radio-hit { width: 20px; height: 20px; flex: 0 0 20px; margin: 0; }
.t1-avatar--lg { width: 48px; height: 48px; font-size: 16px /*fs-lg*/; }
.t1-invacts { display: flex; flex-wrap: wrap; gap: 12px; margin-top: 20px; padding-top: 20px; border-top: 1px solid #E5E8EB /*border-default*/; }
.t1-invacts .t1-btn { flex: 1 1 200px; }
```

`styles/t1.css:627-633`

```css
.t1-roleopt { display: flex; align-items: center; gap: 16px; margin-bottom: 12px; padding: 16px; border: 1px solid #E5E8EB /*border-default*/; border-radius: 12px /*radius-card*/; background: #FFFFFF /*surface-default*/; cursor: pointer; }
.t1-roleopt.is-on { padding: 15.5px; border: 1.5px solid #2F7A3A /*action-primary-default*/; background: #EBF4EE /*surface-success*/; }
.t1-roleopt__ic { flex: 0 0 auto; font-size: 24px; color: #0E1116 /*text-primary*/; }
.t1-roleopt.is-on .t1-roleopt__ic, .t1-roleopt.is-on b { color: #2F7A3A /*action-primary-default*/; }
.t1-roleopt__text { flex: 1; min-width: 0; display: flex; flex-direction: column; gap: 4px; }
.t1-roleopt__text b { font-size: 14px /*fs-md*/; line-height: 22px; font-weight: 700; color: #0E1116 /*text-primary*/; }
.t1-roleopt__text span { font-size: 13px /*fs-sm*/; line-height: 20px; font-weight: 500; color: #4A535E /*text-secondary*/; }
```


CSS đã có ở 10-8g: `.t1-orgm__*`, `.t1-orgp*`, `.t1-orgsec*`, `.t1-kv*`, `.t1-formpage`, `.t1-formcard`.

### Ánh xạ phần tử → Flutter

| Prototype | Flutter |
|---|---|
| `.t1-useg` | `VSegmentedControl(segments: ['Thành viên', 'Lời mời'])` nền trắng; so ảnh, lệch quá 2 px thì vẽ `UsersSegment` riêng |
| `.t1-utools` + `tabs` | `Row` nền `surface` gạch dưới; `VTabs` (giữ `Key('users_tabs')`), ô tìm 360 + nút lọc |
| `.t1-ucard` | `UserListCard` (thay `MemberCard` / `InvitationCard`): `VCard(onTap)`, dòng icon 16 + chữ |
| `.t1-utable` | `AdminTable` |
| `.t1-avatar` 36 / 48 | `DetailAvatar(size: 36 / 48)` |
| `tableSkeleton` 4 dòng | `VSkeletonScope` + `VSkeleton` trong `AdminTable(loadingRows: 4)` |
| `.t1-rolelist` (hẹp), `.t1-rolepick` (web 2 cột) | `RoleRadioList`, `RoleRadioGrid` (`RadioGroup` của Flutter, phím mũi tên) |
| `.t1-invacts` | `Wrap` nút rộng tối thiểu 200, giãn đều; gạch trên, cách 20 / 20 |
| `.t1-btn--danger-outline` | `VButton(variant: secondary, tone: danger)` |
| `usersEmpty` | `UsersEmptyState` (có sẵn), thêm `actionVariant` |

## Bảng "Đang làm gì"

| Thứ bị thay | Đang làm gì | Sau khi sửa | Test giữ hành vi |
|---|---|---|---|
| `UsersAreaShell` + `VListDetailLayout` | Hai cột ≥ 840 | Một trang (**đổi có chủ đích**) | `w2_wide_layout_test` 1, 2, 5, 6, 7, 10 viết lại ở Task 3 |
| Danh sách | Tìm (chờ 300 ms), chip, bộ lọc, chấm lọc, kéo tải lại, cuộn nạp thêm, 5 khối trạng thái | Nguyên; web không kéo tải lại | có sẵn `organization_users_page_test` 11 ca, `organization_users_cubit_test` 6 ca |
| | `canInvite == false` → không có nút mời | Nguyên | có sẵn `invite button presence…` |
| | Đổi tab giữ chữ tìm của từng tab | Nguyên | T0: `search text is kept per tab` |
| Chi tiết → quay về | Danh sách cập nhật sau khi đổi | `onMutated` (Q22) | T0: `suspending in detail refreshes the list badge` |
| ID-15 | Tải vai trò lỗi → "Thử lại"; lỗi dưới ô; trùng → lỗi Email; cảnh báo email; sang chi tiết rồi về | Nguyên | có sẵn 4 ca + cubit 4 ca; T0: `success pushes detail then pops true` |
| ID-16 | Gửi lại / thu hồi / chỉ `pending` có thao tác; `STATE_CHANGED` toast | Nguyên | có sẵn 4 ca; T0: `revoke shows one toast and returns to the list` (viết theo Q16, đỏ trên code cũ — ghi rõ) |
| ID-17 | 3 việc vòng đời + sheet; chủ duy nhất / đã loại không có thao tác | Nguyên | có sẵn 7 ca, cubit 9 ca |
| | `selecting new role and tapping Tiếp tục changes role immediately` | Qua sheet (**đổi có chủ đích**, Q6) | viết lại Task 5 |
| ID-18 | Vai trò hiện tại lên đầu, không chọn được; chưa chọn thì "Tiếp tục" tắt | Nguyên | có sẵn 2 ca |
| `MemberCard` | Nhãn trạng thái, "Chủ sở hữu" | Nguyên trong `UserListCard` | có sẵn 4 ca (đổi tên widget) |

## Review Focus

1. **Trang đầu 20 thành viên không có "Thủ kho", trang hai có:** lọc vai trò ra đúng người, phụ đề "1 thành viên". Test ở Task 2.
2. **Kéo cửa sổ 1280 → 700 khi đang ở chi tiết mở bằng `go`**, rồi ←: về danh sách hẹp, không ném lỗi; làm ngược lại cũng vậy. Test ở Task 4.
3. **Mở thẳng `/more/users/members/m2` (gõ URL) ở 1280:** ← về danh sách, không kẹt. Test ở Task 4.
4. **DB chưa áp migration** (không có khoá): cột "—", không lỗi. Test ở Task 1.
5. **Bàn phím trên web:** Tab vào dòng bảng, Enter mở chi tiết; đọc màn hình đọc "tên, email, vai trò, trạng thái" một lần. Test ở Task 3.

---

### Task 0: Test giữ hành vi trên code cũ

**Files:**
- Modify: `apps/erp/test/features/iam/presentation_module/widgets/{organization_users_page,organization_member_detail_page,organization_invitation_detail_page,organization_invite_member_page}_test.dart`

**Interfaces:**
- Consumes: kịch bản giả trong `test/features/iam/support/scripted_iam_repositories.dart`.
- Produces: không.

- [x] **Step 1: Viết ca T0 trong bảng** ở 390 × 844. Ca `revoke shows one toast…` đánh dấu `skip: 'đỏ trên code cũ, mở ở Task 4 (Q16)'`.
- [x] **Step 2: Chạy, phải xanh trên code cũ** — `cd apps/erp && flutter test test/features/iam/presentation_module/widgets`

### Task 1: Migration "Hoạt động gần nhất" + prototype

**Files:**
- Create: `supabase/migrations/20261128001_iam_list_members_last_activity.sql`, `supabase/tests/iam_member_list.sql`
- Modify: `supabase/migrations/REGISTRY.yaml` (khoá `list_tenant_members`, danh sách file)
- Modify: prototype `app/users.js`, `app/web/users.js`, `app/admin-data.js`, `app/cases.js`, `tests/t1.test.mjs`, `README.md`
- Modify: `apps/erp/lib/features/iam/data/models/tenant_member.dart`, `logic/member_ui_mapper.dart`
- Test: `apps/erp/test/features/iam/data/iam_member_invitation_audit_models_test.dart`, `widgets/member_detail_missing_date_test.dart`

**Interfaces:**
- Produces: `TenantMember.lastActivityAt` (`DateTime?`); `MemberUiModel.lastActiveDate` rỗng khi không có (cả summary và detail).

- [x] **Step 1: SQL** — `create or replace function iam.list_tenant_members(...)` chép nguyên thân `20260820004…sql:117-283`, thêm `u.last_sign_in_at as last_activity_at` ở CTE `filtered` và `'last_activity_at', f.last_activity_at` ở `jsonb_build_object`; giữ `revoke` / `grant`.
- [x] **Step 2: Test SQL** `iam_member_list.sql` (bọc `begin … rollback`, theo khuôn `home_summary.sql`): `m1_owner_sees_last_activity` (khác null khi đã đăng nhập, null khi chưa), `m2_staff_denied` (`PERMISSION_DENIED`), `m3_cursor_and_search_unchanged`. Run (người dùng): `tools/db_check.sh iam_member_list` → xanh.
- [x] **Step 3: Prototype** — Q3, Q4, Q5, Q18, Q20 (không đổi ảnh vì chỉ có pending / hết hạn), Q21: `filterSheet('invitations')`, `usersEmpty` lời mời, `INVITE_STATES['empty-submit']` có cả `role`, nhãn `*` + khe ở `revokeSheet`, dòng "Quyền sở hữu", gợi ý email (hai khung); thêm ca `['confirm', 'Xác nhận đổi vai trò (sheet)', …]` ở `select-role` dùng `lifecycleSheet` với chữ Q6. Sửa câu mô tả ca, README mục 44, 45, 46, 47. `node --test` PASS; `node tools/capture.mjs users`, `invite`, `invitation-detail`, `member-detail`, `select-role`; chép lại ảnh ở mục Ảnh và `select-role__confirm` hai khung.
- [x] **Step 4: Viết test Dart** — `TenantMember.fromJson` có / không có `last_activity_at`; `member_detail_missing_date_test`: thiếu hoạt động → "—" (Q17).
- [x] **Step 5: Chạy → FAIL, cài đặt, chạy → PASS** — `flutter test test/features/iam/data test/features/iam/presentation_module/widgets/member_detail_missing_date_test.dart`

### Task 2: Logic danh sách, mời, lời mời

**Files:**
- Modify: `logic/organization_users_{cubit,state}.dart`, `logic/organization_invite_member_cubit.dart`, `logic/organization_invitation_detail_cubit.dart`, `logic/invitation_ui_mapper.dart`, `logic/user_ui_model.dart`, `logic/member_ui_mapper.dart`, `core/iam/iam_role_label_mapper.dart`
- Test: `users/{organization_users_cubit,organization_invite_member_cubit,organization_invitation_detail_cubit,invitation_ui_mapper}_test.dart`, `logic/member_role_filter_test.dart`, `shared/iam_role_label_mapper_test.dart`

**Interfaces:**
- Produces:

```dart
// OrganizationUsersState: bool get isMemberFiltered; IamUiFailure? loadMoreFailure (copyWith + clearLoadMoreFailure)
// OrganizationUsersCubit: void clearLoadMoreFailure()
// InvitationUiModel: final String expiryLabel; final String deliveryLabel;
// MemberUiModel.identityText: 'Chủ sở hữu' | 'Thành viên'
```

- [x] **Step 1: Viết test**

```dart
test('role filter loads every page and finds a member on page 2', …)      // listMembers gọi 2 lần với limit 100; members.length == 1
test('role filter with no match is reported as filtered', …)              // isMemberFiltered isTrue
test('name sort ignores Vietnamese tones', …)                              // 'Ân', 'Bình', 'Đạt', 'Em' đúng thứ tự A–Z
test('a stale members response is dropped', …)                             // trả lời thứ nhất về sau → state giữ trả lời thứ hai
test('custom range uses Vietnam days', …)                                  // tạo 2026-07-30T17:30Z (00:30 31/07 VN): khoảng 20–30/07 không có, 31/07 có
test('load more failure keeps the list', …)                                // members còn, memberStatus success, loadMoreFailure khác null
test('status filter revoked is sent to the server', …)                     // 'revoked'
test('empty submit flags both fields', …)                                  // emailError và roleError cùng câu
test('revoke has no success message', …)
test('terminal invitations have no expiry label; unknown delivery is —', …)
test('store_owner description has no technical note', …)
```

- [x] **Step 2: Chạy → FAIL** — `cd apps/erp && flutter test test/features/iam/presentation_module/users test/features/iam/logic test/features/iam/presentation_module/shared`
- [x] **Step 3: Cài đặt** Q3, Q4, Q10–Q16, Q18, Q20, Q21. Ca cũ `filters invitations by sendResult (Đã gửi, Gửi lỗi, Thu hồi)`: phần "Thu hồi" chuyển sang ca trạng thái.
- [x] **Step 4: Chạy → PASS** (lệnh Step 2)

### Task 3: Danh sách (ID-14)

**Files:**
- Create: `iam/presentation/shared/admin_table.dart`, `users/widgets/{users_narrow,users_wide,user_list_card}.dart`, `apps/erp/test/features/iam/presentation_module/shared/admin_table_test.dart`, `apps/erp/test/features/iam/presentation_module/users_golden_test.dart`
- Modify: `users/users_area_shell.dart`, `users/views/organization_users_page.dart`, `users/widgets/{organization_users_body,member_list_section,invitation_list_section,users_empty_state,invitation_filter_bottom_sheet}.dart`, `core/router/app_router.dart:713-796`
- Delete: `users/widgets/{member_card,invitation_card}.dart`
- Test: `organization_users_page_test.dart`, `invitation_filter_bottom_sheet_test.dart`, `users/member_card_test.dart` (→ `user_list_card_test.dart`), `w2_wide_layout_test.dart`

**Interfaces:**
- Consumes: `isWideLayout`, `DetailAvatar`.
- Produces (10-8i dùng):

```dart
class AdminTableColumn { const AdminTableColumn(this.label, {this.flex = 1, this.minWidth = 0}); }
class AdminTableRow { const AdminTableRow({required List<Widget> cells, required VoidCallback onTap, required String semanticLabel}); }
class AdminTable extends StatelessWidget {
  const AdminTable({super.key, required List<AdminTableColumn> columns, required List<AdminTableRow> rows, int loadingRows = 0, Widget? state, String? semanticLabel});
} // loadingRows > 0: khung xương; state != null: hàng tiêu đề ẩn, khối giữa cao ≥ 360; cột mũi tên 24 tự thêm
class AdminTablePage extends StatelessWidget { // thân 1120, đệm 20 / 24 / 32, cuộn; onNearEnd cho nạp thêm
  const AdminTablePage({super.key, required List<Widget> children, VoidCallback? onNearEnd});
}
// UsersAreaShell({super.key, required Widget child, members, invitations, cubit}) — chỉ cấp cubit, bỏ selectedId / canInvite
```

- [x] **Step 1: Viết test**

```dart
// admin_table_test.dart
testWidgets('rows open on tap and Enter, one semantics node each', …)
testWidgets('loading shows n skeleton rows and no chevrons', …)
testWidgets('fits 840 wide', …)                                         // takeException isNull
// organization_users_page_test.dart
testWidgets('1280: table with four headers and last activity', …)       // 'Hoạt động gần nhất', '21/11/2026 17:05'; tạm ngừng '—'
testWidgets('1280: invite button in the app bar, no bottom bar', …)
testWidgets('390: invite in the bottom bar, hidden on failure and on empty', …)
testWidgets('1280: tapping a row goes to the member url and back returns', …)
testWidgets('role filter with no match shows Không tìm thấy kết quả', …)
testWidgets('load more failure shows a toast and keeps rows', …)
testWidgets('invitations empty text follows TH-01', …)
testWidgets('320 at text scale 2.0 does not overflow', …)
// w2_wide_layout_test.dart: 1 → '1280 hiện bảng, không có VListDetailLayout'; 2, 6, 7, 10 viết lại theo bảng; 5 bỏ phần Người dùng
// một golden có khung: StoreShell thật 1280 + Người dùng (thanh bên 84, thân 1196)
```

- [x] **Step 2: Chạy → FAIL** — `flutter test test/features/iam/presentation_module/widgets/organization_users_page_test.dart test/features/iam/presentation_module/shared test/features/iam/presentation_module/w2_wide_layout_test.dart`
- [x] **Step 3: Cài đặt** Q2, Q9, Q22, Q23. Router: bỏ nhánh `VListDetailLayout.isSplitOf` và khối "Chọn một thành viên…"; `GoRoute('/more/users')` luôn dựng `OrganizationUsersPage`. Mời xong: `selectTab(invitations)` rồi `loadInvitations(reset: true)` (Q19).
- [x] **Step 4: Chạy → PASS** (lệnh Step 2) và `flutter test test/features/invitations`
- [x] **Step 5: Golden** `users__{members,invitations,loading,invitations-empty,no-results,forbidden,filter-applied,filter-invitations}` × 2 + golden có khung. So ảnh, ghi lệch.

### Task 4: Chi tiết lời mời, chi tiết thành viên (ID-16, ID-17)

**Files:**
- Create: `users/widgets/{invitation_detail_narrow,invitation_detail_wide,member_detail_narrow,member_detail_wide}.dart`
- Modify: `users/views/organization_invitation_detail_page.dart`, `organization_member_detail_page.dart`, `users/widgets/revoke_invitation_bottom_sheet.dart`
- Delete: `users/widgets/member_detail_body.dart`; `member_detail_bottom_sheets.dart` nếu không còn ai dùng (grep)
- Test: `organization_invitation_detail_page_test.dart`, `organization_member_detail_page_test.dart`, `w2_wide_layout_test.dart` (8, 9, 11, 12, 14), `users_golden_test.dart`

**Interfaces:**
- Consumes: `detail_layout.dart` (10-8g).
- Produces:

```dart
const InvitationDetailNarrow({super.key, required InvitationUiModel invitation, required String statusLabel, required VComponentTone statusTone});
const InvitationDetailWide({…như trên, required VoidCallback? onResend, required VoidCallback? onRevoke, required InvitationMutation? busy});
const MemberDetailNarrow({super.key, required MemberUiModel member});
const MemberDetailWide({super.key, required MemberUiModel member, required VoidCallback? onChangeRole, onDeactivate, onReactivate, onRemove, required MembershipMutation? busy});
// callback null = không hiện nút; busy != null = mọi nút tắt, nút của việc đó xoay
```

- [x] **Step 1: Viết test** (mở `skip` của T0 `revoke shows one toast…`)

```dart
testWidgets('1280: resend and revoke inside the section, no Thao tác', …)
testWidgets('1280: expired invitation has no actions', …)
testWidgets('1280: member actions follow status and sole owner', …)      // active: 3 nút; suspended: 'Kích hoạt lại'; owner / removed: không nút
testWidgets('1280: running action spins and disables the others', …)
testWidgets('390: Thao tác sheets unchanged', …)
testWidgets('390 and 1280: ownership row, no Chỉ đọc', …)
testWidgets('detail always has back; deep link back goes to the list', …) // initialLocation /more/users/members/m2, 1280
testWidgets('resizing 1280 → 700 in detail then back works', …)
testWidgets('revoke reason is required and spaced', …)                    // ' *'; khe 16
testWidgets('320 at text scale 2.0 does not overflow', …)
```

- [x] **Step 2: Chạy → FAIL** — `flutter test test/features/iam/presentation_module/widgets/organization_invitation_detail_page_test.dart test/features/iam/presentation_module/widgets/organization_member_detail_page_test.dart test/features/iam/presentation_module/w2_wide_layout_test.dart`
- [x] **Step 3: Cài đặt** Q5, Q16, Q22–Q24; `showBackButton` luôn `true`.
- [x] **Step 4: Chạy → PASS** (lệnh Step 2)
- [x] **Step 5: Golden** `invitation-detail__{pending,expired,revoke}`, `member-detail__{active,suspended,removed,owner,deactivate}` × 2; ba ca sheet "Thao tác" × 390. So ảnh.

### Task 5: Mời thành viên, chọn vai trò (ID-15, ID-18) + dọn

**Files:**
- Create: `users/widgets/{role_radio_list,role_radio_grid,change_role_bottom_sheet,invite_narrow,invite_wide,select_role_narrow,select_role_wide}.dart`
- Modify: `users/views/{organization_invite_member_page,organization_select_role_page,organization_member_detail_page}.dart`, `docs/requirements/TH-01-to-chuc-va-nguoi-dung.md`, `docs/refactor/{PLAN,CHECKLIST}.md`
- Delete: `users/views/organization_preview_role_change_page.dart`, export ở `iam/presentation.dart:53`, `widgets/organization_preview_role_change_page_test.dart`
- Test: `organization_invite_member_page_test.dart`, `organization_select_role_page_test.dart`, `organization_member_detail_page_test.dart`, `users_golden_test.dart`

**Interfaces:**
- Produces:

```dart
class RoleChoice { const RoleChoice({required String id, required String title, required String description, bool isCurrent = false}); }
class RoleRadioList extends StatelessWidget { const RoleRadioList({super.key, required List<RoleChoice> roles, required String? value, required ValueChanged<String>? onChanged, bool invalid = false}); }
class RoleRadioGrid extends StatelessWidget { /* cùng tham số */ }
Future<bool?> showChangeRoleBottomSheet({required BuildContext context, required String memberName, required String fromRole, required String toRole, required Future<bool> Function() onConfirm});
class OrganizationSelectRolePage { const OrganizationSelectRolePage({super.key, required MemberUiModel member, required Future<bool> Function(String roleCode) onConfirm, List<InvitationRoleOption>? invitationRoleOptions}); }
```

- [x] **Step 1: Viết test**

```dart
testWidgets('390: invite roles are four radio rows; 1280: two-column grid', …)
testWidgets('empty submit marks both email and roles', …)
testWidgets('submitting disables email and roles', …)
testWidgets('arrow keys move the role selection', …)
testWidgets('Tiếp tục opens the confirm sheet with from → to', …)            // 'Đổi vai trò của Trần Văn Minh?', 'Vai trò Nhân viên bán hàng → Thủ kho.'
testWidgets('Quay lại keeps the selection', …)                               // không gọi assignRole
testWidgets('Xác nhận thay đổi changes the role, closes both, shows one toast', …)
testWidgets('a failed change keeps the sheet open and shows the toast', …)   // LAST_OWNER_PROTECTED
testWidgets('success returns to the invitations tab', …)                     // Q19
testWidgets('320 at text scale 2.0 does not overflow', …)
```

- [x] **Step 2: Chạy → FAIL** — `flutter test test/features/iam/presentation_module/widgets/organization_invite_member_page_test.dart test/features/iam/presentation_module/widgets/organization_select_role_page_test.dart test/features/iam/presentation_module/widgets/organization_member_detail_page_test.dart`
- [x] **Step 3: Cài đặt** Q4, Q6–Q8, Q19, Q21.
- [x] **Step 4: TH-01** — 3.4 mô tả `store_owner` "Quản lý toàn bộ cửa hàng" (ghi chú BR-36 chuyển xuống dưới bảng); US-06.4 FR-01: "Quyền sở hữu: Chủ sở hữu / Thành viên"; US-06.1 thêm "Hoạt động gần nhất" ở bảng web. CHECKLIST ID-18b giữ như 10-8d.
- [x] **Step 5: Chạy → PASS**

Run: `cd apps/erp && flutter test test/features/iam test/features/invitations && dart analyze lib test && dart run tool/check_feature_imports.dart`
Expected: PASS, không lỗi analyze mới, không vi phạm import mới

- [x] **Step 6: Golden** `invite__{empty,filled,empty-submit}`, `select-role__{default,selected,confirm}` × 2. So ảnh.
- [x] **Step 7: PLAN.md** dòng Theme 1: 10-8h đã làm

## Kiểm tay (người dùng)

- [x] DB: `tools/db_check.sh iam_member_list` xanh (2026-11-26).
- [ ] Áp Dev khi đồng ý (`supabase db push`).
- [ ] Web + iPhone: tìm, lọc từng tiêu chí, mời (trống, sai, trùng, đúng), gửi lại, thu hồi, tạm ngừng, kích hoạt lại, loại, đổi vai trò.
- [ ] Web: gõ thẳng URL chi tiết, ← của trang và của trình duyệt; thu cửa sổ khi đang ở chi tiết.
- [ ] CHECKLIST ID-14…ID-18 cột "Mới".

## Kết quả

Làm xong Task 0–5; xử lý review R1 (2026-11-26). Golden `test/features/iam/presentation_module/users_golden_test.dart`: 47 ảnh, dữ liệu trùng `admin-data.js`, so cạnh prototype ở mục Ảnh. Còn lệch chấp nhận được:

- Icon ra ô vuông, không có ← trên app bar: golden không nạp font icon và trang không có route để quay lại (giống 10-8g).
- Ngày giờ "21/11/2026 · 17:05" (`VDateTime.dateTime` dùng chung toàn app); prototype viết "21/11/2026 17:05".
- Web: thẻ vai trò ở Mời thành viên cao hơn ~3 px; iPhone: chữ phụ đề đầu trang Chọn vai trò cỡ `bodyDefault` (prototype nhỏ hơn 1 cỡ).
- Web chi tiết thành viên tạm ngừng: ô chữ viết tắt xám (`DetailAvatar(muted)`, như bản iPhone); prototype web giữ màu xanh.

Kiểm: `flutter test test/features/iam test/features/invitations` 448 PASS; `node --test tests/t1.test.mjs` 24 PASS; `dart analyze` phần iam không có mục mới; `check_feature_imports` không vi phạm iam. `tools/db_check.sh iam_member_list` đạt (người dùng chạy 2026-11-26; lần đầu đỏ do test dùng mã vai trò `sales_staff` và chèn trùng profile mà `trg_on_auth_user_confirmed_ins` đã tạo — sửa thành `staff` + `on conflict`). Còn: kiểm tay, áp Dev.

## Review

**R1 (2026-11-26):** Test xanh, migration chép đúng, Q1–Q5, Q7–Q24 đúng. Thiếu bước và lỗi, đã sửa:

| # | Lỗi | Sửa |
|---|---|---|
| A | Task 1 Step 3: prototype chưa sửa (còn "Danh tính: Chỉ đọc", `minhphat.vn`, "Thu hồi" ở "Kết quả gửi", "Chưa có lời mời"), không có ca `select-role__confirm` | Sửa `users.js`, `web/users.js`, `admin-data.js` (Q20 `statusDetail`), `cases.js`, README 44–47; thêm `changeRoleSheet` + ca `confirm`; 3 ca `node --test`; chụp lại 5 màn, chép ảnh |
| B | Chưa có golden, chưa so ảnh | `users_golden_test.dart` (bọc `RepaintBoundary` ở `MaterialApp.builder` để sheet lọt vào ảnh); so từng cặp, sửa các lệch 8–13 |
| 1 | Đổi vai trò lỗi vẫn đóng sheet và trang "Chọn vai trò": `onConfirm` đọc `state.failure` sau khi listener đã `clearFeedback()`. Ca test cũ xanh giả vì `memberLastOwnerProtected` không chặn `assignRole` (đổi thành công thật) | `changeRole` trả `Future<bool>`; `onConfirm: cubit.changeRole`. Test dùng repo chặn `assignRole` + `pumpAndSettle`; đỏ với code cũ, xanh với code mới |
| 2 | Web: chủ duy nhất tạm ngừng vẫn có "Thay đổi vai trò", "Loại khỏi tổ chức" | Dùng `canChangeRole` / `canRemove`; thêm ca `1280: suspended sole owner only shows Kích hoạt lại` |
| 3 | Info analyze mới: `_UserCardLine` private trong API public; `hasFlag` deprecated | `UserCardLine`; `flagsCollection.isSelected` |
| 4 | `selectedId` không ai truyền (5 file) | Xoá |
| 5 | Comment cũ ở `invitation_filter_bottom_sheet.dart:6-7` | Sửa |
| 6 | Review Focus 2, 3 chỉ test bằng router tự dựng | Thêm `1b`, `1c` ở `w2_wide_layout_test` dùng `appRouter` (go ở 1280 → 700 → ←; URL ở 700 → 1280 → ←) |
| 7 | (Rút lại) "toast nạp thêm lặp chữ": `VToast` chỉ vẽ `message`, `title` dùng cho trình đọc màn hình | Giữ nguyên |
| 8 | Web danh sách: `VPageScaffold` giới hạn thân 720 → bảng hẹp, tên / vai trò xuống dòng | `contentMaxWidth: VPageScaffold.fullWidth` khi rộng |
| 9 | Web: tab giãn hết hàng; hai gạch chồng dưới tab (README 41) | `VTabsList(isScrollable: true)`; dịch tab 1 px trùng gạch hàng công cụ |
| 10 | Nhãn lời mời sai chữ / màu so với prototype và `InvitationCard` cũ ("Gửi lỗi", Đang chờ xám, Hết hạn / Đã thu hồi đỏ) | "Lỗi gửi"; Đang chờ vàng; Hết hạn, Đã thu hồi xám |
| 11 | iPhone thẻ danh sách: nhãn "Chủ sở hữu" và trạng thái chồng ở giữa | Tên + nhãn phụ liền nhau, nhãn trạng thái dạt phải (`.t1-ucard__name`) |
| 12 | Mời thành viên: chọn sẵn vai trò đầu → không bao giờ báo thiếu vai trò (Q4, TH-01 US-06.2 FR-01/06, prototype không chọn sẵn); iPhone nhãn "Vai trò ban đầu" nằm ngoài thẻ; web khe nhãn → lưới 16 (proto 8), radio 32 | Bỏ chọn sẵn (6 test cũ thêm bước chọn vai trò; `empty email…` đếm 2 câu lỗi); `RoleRadioList(header:)`; bỏ `SizedBox(8)` thừa; radio 20 × 20 |
| 13 | iPhone Chọn vai trò: nhãn "Hoạt động" xuống dưới hai dòng phụ; khe 24 trước "Chọn vai trò mới" (proto ~12) | `DetailHeaderNarrow(badgeInline: true)` (mặc định giữ như 10-8g, golden 10-8g không đổi); khe 12 |

DB: `tools/db_check.sh iam_member_list` đạt sau khi sửa test SQL (mã vai trò `staff`; upsert profile).
