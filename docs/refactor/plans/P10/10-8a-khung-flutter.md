# 10-8a Khung chung về Flutter: thanh biểu tượng web — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Web ≥ 1024 thay thanh bên 240 bằng thanh biểu tượng 84 có menu nổi "Quản lý" đúng prototype `specs/prototype/shared/shell.{js,css}`; khung thôi bó nội dung 1120 cho nhánh Trang chủ.

**Architecture:** Viết lại `VSideNavigation` (DS) thành thanh biểu tượng: mục không có `children` là tab icon + nhãn ở trên; mục có `children` vẽ ở đáy (sau khoảng giãn) và bấm thì mở menu nổi (`OverlayPortal`) liệt kê mục con kèm mô tả. Giữ nguyên hợp đồng `items` / `selected (int, int?)` / `onSelect(int, int?)` / `header` / `footer` nên `ErpSideNavigation` chỉ đổi phần đầu (ô tổ chức 40), phần cuối (tab Đăng xuất) và nhãn "Quản lý". Bề ngang: `StoreShell` thôi bó `VContentWidth` khi đường dẫn là `/` (Trang chủ), mọi route khác trong khung giữ bó 1120.

**Tech Stack:** Flutter, `c45_design_system` (path package), go_router, flutter_bloc, `lucide_icons_flutter` 3.1.25.

**Spec:** bản thiết kế "10-8 bước 4: Chuyển khung chung về Flutter" duyệt trong chat 2026-11-23; mục 10-8a của bản đó chép ở "Thiết kế đã duyệt" bên dưới. Nguồn hình: `specs/prototype/shell/html/README.md` mục "Đề xuất đã chốt, chưa có trong Flutter (2026-11-23)".

## Thiết kế đã duyệt (mục 10-8a)

- Web ≥ 1024: thanh biểu tượng rộng 84; trên cùng ô tổ chức (chữ cái đầu, bấm mở APP-04); 4 tab icon + nhãn (web **không có "Thêm"**); "Quản lý" mở menu nổi "Quản lý cửa hàng" gồm mục phụ có mô tả, lọc như hiện nay (`isVisible`: nhân viên không thấy "Người dùng & vai trò"); đang ở mục phụ thì "Quản lý" sáng, mục trong menu tô nền brand; Đăng xuất ở đáy.
- iPhone / < 1024: thanh dưới 5 tab giữ nguyên.
- Sửa `v_side_navigation.dart` (đổi sang thanh biểu tượng + menu nổi; chỉ ERP và preview DS dùng), nâng version DS (minor), `erp_side_navigation.dart`, `store_shell.dart`, mục Navigation trong `DESIGN.md`.

## Global Constraints

- Không đổi màu / font Mosaic; mọi màu qua `context.vColors` / `VColors`, khoảng cách `VSpacing`, bo `VRadius`, chữ `VTypography`.
- Token HTML khớp Dart: token mới thêm ở Dart phải bằng đúng giá trị trong `specs/prototype/shared/tokens.css`.
- Kiến trúc: `dashboard` không import `logic/` / `presentation/` của feature khác ngoài những import đã có (`more_entries.dart`, `more_logout.dart`, `tenant_context_selector.dart`); kiểm `dart run tool/check_feature_imports.dart`.
- Chỉ chạy test phạm vi plan (liệt kê ở từng task); **không** chạy `flutter test` toàn app.
- Không đụng `/more` (route, `MorePage`) và thanh dưới: thuộc 10-8c / giữ nguyên.
- 10-7 còn task "Cuối" (`document` DESIGN.md + bump DS). Plan này bump `1.7.0` → `1.8.0` và sửa mục Navigation của `DESIGN.md`; 10-7 "Cuối" làm sau thì bump tiếp từ `1.8.0` và giữ mục Navigation đã sửa ở đây.
- Icon tab giữ `ErpTab.icon` (Material) như thanh dưới hiện tại; icon mới chỉ có `VIcons.layers` (Quản lý). Prototype dùng nét Lucide là khác biệt có chủ đích (README shell).

## Quyết định

| # | Quyết định | Lý do |
|---|---|---|
| Q1 | **Bề ngang:** `StoreShell._buildLayout` (desktop) bỏ `VContentWidth` **chỉ khi** `GoRouterState.of(context).matchedLocation == '/'`; mọi route khác giữ `VContentWidth(child: content)` như cũ. `ErpTabScaffold` không đổi. Hệ quả: thẻ "bị chặn" ở `/` rộng hết (khớp `session__blocked`); ở `/orders`… vẫn trong 1120 (lệch nhỏ với prototype, để theme đó rà). | Người dùng chọn 2026-11-23 theo `shell.css:19-22` (khung không bó, mỗi trang tự bó). `ShellRoute(StoreShell)` ở `app_router.dart:473` đóng ở **dòng 1234**: bao cả `/more/settings`, `/more/my-account`, `/more/users-and-roles`, `/pricing`, công nợ, mọi route Theme 7 (`stockRoutes`, `goodsReceiptRoutes`, `stocktakeRoutes`, `costingRoutes`, `reportsRoutes`) — không đi qua `ErpTabScaffold`. Bỏ bó ở khung cho mọi route sẽ giãn các trang đó (Theme 7 FROZEN) ra 1196, nên chỉ mở cho Trang chủ (tự bó ở 10-8b); route khác mở dần khi theme của nó rà |
| Q2 | Hover tab / mục menu dùng token mới `VColors.neutral150 = 0xFFF1F3F5` qua trường mới `VColorScheme.surfaceHoverStrong` (sáng `neutral150`, tối `neutral500`). | Prototype dùng `--c45-v2-neutral-150`; Dart chưa có. `surfaceHover` (`neutral50`) nhạt hơn |
| Q3 | Menu nổi bằng `OverlayPortal` + `CompositedTransformTarget/Follower` (`targetAnchor: Alignment.bottomRight`, `followerAnchor: Alignment.bottomLeft`, `offset: Offset.zero`), `TapRegion` đóng khi bấm ngoài, Esc đóng, chọn mục thì đóng. Không dùng `MenuAnchor`. Menu sát mép phải nút (khe 0): `.sh-side__menu { margin-left: 12px }` (`shell.css:41`) bị `.sh-menu { margin: 0 }` (`:44`, cùng độ ưu tiên, đứng sau) đè; ảnh `proto-shell-menu-*` cho thấy menu bắt đầu ở x≈76 — làm theo ảnh. | `MenuAnchor` áp style menu Material, khó khớp CSS `.sh-menu` |
| Q4 | Mục có `children` luôn vẽ ở đáy (sau `Spacer`) và mở menu; bấm nó **không** gọi `onSelect(i, null)`. `VSideNavigationItem` thêm `description` (dòng phụ trong menu) và `menuTitle` (tiêu đề menu, mặc định = `label`). | Giữ được hợp đồng `selected` / `onSelect` cũ: `ErpTab.more` vẫn là index 4 |
| Q5 | `header` / `footer` vẫn là `Widget?`; DS thêm widget công khai `VSideNavigationAction` (tab icon + nhãn, `destructive`) để ERP dựng nút Đăng xuất giống tab. | Phần cuối prototype là một tab (`.sh-side__tab.sh-side__logout`), không còn hàng chữ có viền trên |
| Q6 | Ở 1024–1080 trang Sản phẩm / Đối tác giờ chia 2 cột (bề ngang layout 940 ≥ 840 của `VListDetailLayout`), trước đây một cột. Chấp nhận, ghi vào `DESIGN.md`. | Hệ quả trực tiếp của thanh 84 |

## Bảng "Đang làm gì" (thay `VSideNavigation`, `ErpSideNavigation`, bề ngang ở `StoreShell`)

| Thứ bị thay | Đang làm gì | Sau khi sửa nằm ở đâu | Test giữ hành vi |
|---|---|---|---|
| `ErpSideNavigation` | Vị trí từ `currentLocation` hoặc `GoRouterState.matchedLocation` | giữ nguyên | `store_shell_test` "wide 1280 … tab navigation works" |
| | `isOwner`, `isBlocked`, tên tổ chức (mặc định `Chưa chọn tổ chức`) từ `SessionController` | giữ nguyên; tên dùng cho chữ cái đầu + tooltip + semantics | mới T0: `blocked session at 1280: org tile shows store icon, label "Đổi tổ chức, Chưa chọn tổ chức"` |
| | Tab chọn = `ErpTab.fromLocation`; mục con chọn = `selectedMoreEntry` trong danh sách đã lọc | giữ nguyên | "wide 1280 on /more/users/invite" (`selected == (4, 3)`) |
| | Lọc `ownerOnly` khi không phải chủ và không bị chặn | giữ nguyên | mới T0: `staff at 1280: menu has no "Người dùng & vai trò"` |
| | Mục con `enabled = isInteractive(isBlocked)` | giữ nguyên (mục mờ trong menu, bấm không làm gì) | mới T0: `blocked at 1280: "Kho" disabled, "Tài khoản của tôi" enabled` |
| | `tab.enabled` | giữ nguyên | DS test `disabled main item …` |
| | Đầu: bấm → `openTenantContextSelector`; semantics `Đổi tổ chức, <tên>` | ô tổ chức 40 (`_SideNavOrgTile`) | mới T0: `tap org header opens tenant selector` (tìm theo semantics label, giữ được sau khi đổi widget) |
| | Cuối: bấm → `signOutAndGoToLogin`; màu `danger` | `VSideNavigationAction(destructive: true)` | mới T0: `tap "Đăng xuất" signs out` (fake repository ghi nhận `signOut`) |
| | `onSelect(i, null)` → `context.go(ErpTab.values[i].routePath)`; `onSelect(i, c)` → `context.go(route)` nếu có | giữ nguyên | "wide 1280 … tab navigation works"; mới T0: `tap sub-entry "Kho" goes to /warehouse` |
| `VSideNavigation` | Nền `surface`, viền phải hairline `borderDefault` | giữ nguyên | T0 DS: `has surface background and right hairline` |
| | Mục chính chọn đúng → `surfaceBrand`; nhánh có con chọn → `surfaceBrand` 50% | tab chọn → `surfaceBrand`; "Quản lý" khi `selected.$2 != null` hoặc `selected.$1` là nó → `surfaceBrand` (prototype không còn 50%) — **đổi có chủ đích** theo prototype | DS mới: `parent with selected child is highlighted` |
| | Mục tắt mờ `vDisabledOpacity`, `onTap` null | giữ nguyên ở tab và mục menu | DS `disabled main item and child do not call onSelect` (đổi cách mở menu, giữ điều kiện) |
| | `MergeSemantics` + `Semantics(button, selected, enabled)` | giữ nguyên ở tab và mục menu | DS `exposes semantics button role and selected state` |
| | Viền focus 2 khi focus bàn phím; Enter / Space kích hoạt | giữ nguyên ở tab, ô tổ chức, mục menu | DS `Tab moves focus through items and Enter key activates onSelect` |
| | Vùng chạm ≥ 44 | tab ≥ 60, mục menu ≥ 44 | T0 DS: `every item is at least 44 tall` |
| | Chữ phóng tối đa ×1.3, 1 dòng `…` | giữ nguyên | T0 DS: `labels stay on one line under text scale 2.0` |
| | `vInspectorHide` bọc ngoài | giữ nguyên | — (công cụ dev, không test) |
| | Header / footer tuỳ chọn | giữ nguyên | DS `renders header and footer when provided` |
| `StoreShell._buildLayout` | Desktop: `Row(ErpSideNavigation, Expanded(VContentWidth(content)))` trên `Material(background)` — bó 1120 cho **mọi** route trong khung, kể cả route không qua `ErpTabScaffold` | giữ nguyên, trừ `/` không bó (Q1) | mới T0: `1280 on /orders: content width ≤ 1120`, `1280 on /more/my-account: content width ≤ 1120`; sau sửa thêm `1280 on /: content width 1196` |

## Ảnh

Nguồn: `specs/prototype/shell/html/tools/proto-final/` chụp lại 2026-11-23 sau khi đổi thanh biểu tượng; ảnh có menu mở chụp riêng (`showPopover()` sau khi nạp). Cột Flutter phiên code thêm bằng golden test (Task 3).

| Prototype | Flutter |
|---|---|
| ![](img/10-8a/proto-shell-tab-home-1280.png) | ![](img/10-8a/flutter-shell-tab-home-1280.png) |
| ![](img/10-8a/proto-shell-tab-orders-1280.png) | ![](img/10-8a/flutter-shell-tab-orders-1280.png) |
| ![](img/10-8a/proto-shell-sub-warehouse-1280.png) | ![](img/10-8a/flutter-shell-sub-warehouse-1280.png) |
| ![](img/10-8a/proto-shell-menu-sub-warehouse-1280.png) | ![](img/10-8a/flutter-shell-menu-sub-warehouse-1280.png) |
| ![](img/10-8a/proto-shell-menu-session-staff-1280.png) | ![](img/10-8a/flutter-shell-menu-session-staff-1280.png) |
| ![](img/10-8a/proto-shell-menu-session-blocked-1280.png) | ![](img/10-8a/flutter-shell-menu-session-blocked-1280.png) |
| ![](img/10-8a/proto-shell-session-blocked-1280.png) | ![](img/10-8a/flutter-shell-session-blocked-1280.png) |
| ![](img/10-8a/proto-shell-session-long-org-1280.png) | ![](img/10-8a/flutter-shell-session-long-org-1280.png) |
| ![](img/10-8a/proto-shell-session-narrow-900.png) | ![](img/10-8a/flutter-shell-session-narrow-900.png) |
| ![](img/10-8a/proto-shell-tab-home-390.png) | ![](img/10-8a/flutter-shell-tab-home-390.png) |

Hai ảnh cuối (900, 390) là thanh dưới: phải **không đổi** so với Flutter hiện tại.

## Code prototype (chép nguyên văn)

`specs/prototype/shared/shell.js:83-106`

```js
/** Thanh biểu tượng web (≥ 1024) — ĐỀ XUẤT thay ErpSideNavigation 240 (chưa có trong Flutter).
 *  Rộng 84: ô tổ chức (bấm để đổi), 4 tab (icon + nhãn, không có "Thêm"), "Quản lý" mở menu nổi
 *  (popover) chứa 6 tính năng phụ kèm mô tả, Đăng xuất ở đáy. Đang ở một tính năng phụ → "Quản lý" sáng. */
export function sideNav({ location = '/', isOwner = true, isBlocked = false, orgName = 'Chưa chọn tổ chức' } = {}) {
  const tab = tabFromLocation(location);
  const sel = tab === 'more' ? selectedMoreEntry(location) : null;
  const tabs = TABS.filter((t) => t.id !== 'more').map((t) => {
    const on = t.id === tab;
    return `<button type="button" class="sh-side__tab${on ? ' is-on' : ''}" data-shell-route="${t.route}"${on ? ' aria-current="page"' : ''}>${icon(t.icon)}<span>${esc(t.label)}</span></button>`;
  }).join('');
  const subs = visibleSubEntries({ isOwner, isBlocked }).map((e) => {
    const on = sel?.id === e.id;
    return `<button type="button" class="sh-menu__item${on ? ' is-on' : ''}" data-shell-route="${e.route}"${on ? ' aria-current="page"' : ''}${isInteractive(e, { isBlocked }) ? '' : ' disabled'}><span class="sh-menu__icon">${icon(e.icon)}</span><span class="sh-menu__text"><b>${esc(e.title)}</b><small>${esc(e.subtitle)}</small></span></button>`;
  }).join('');
  const initial = isBlocked ? '' : esc(String(orgName).trim().charAt(0).toUpperCase());
  return `<nav class="sh-side" aria-label="Điều hướng chính">
    <button type="button" class="sh-side__org" data-shell-org aria-label="Đổi tổ chức, ${esc(orgName)}" title="${esc(orgName)}">${initial || icon('store')}</button>
    ${tabs}
    <span class="sh-side__spacer"></span>
    <button type="button" class="sh-side__tab sh-side__manage${tab === 'more' ? ' is-on' : ''}" popovertarget="sh-manage-menu">${icon('layers')}<span>Quản lý</span></button>
    <button type="button" class="sh-side__tab sh-side__logout" data-shell-logout>${icon('logout')}<span>Đăng xuất</span></button>
    <div id="sh-manage-menu" class="sh-menu sh-side__menu" popover><p class="sh-menu__title">Quản lý cửa hàng</p>${subs}</div>
  </nav>`;
}
```

`specs/prototype/shared/shell.css:16-22` (bề ngang; bỏ dòng `.sh-mobile`) và `:26-57` (thanh + menu); token thay bằng giá trị trong `tokens.css` (tên token giữ trong chú thích), `--sh-fs-*` thay bằng px:

```css
.sh-desktop { flex: 1; min-height: 0; display: flex; }
.sh-main { flex: 1; min-width: 0; min-height: 0; display: flex; flex-direction: column; overflow: hidden; }
/* Vùng nội dung web: tràn hết bề ngang để app bar + đường kẻ chạy suốt tới mép phải.
   Không bó 1120 ở khung (đó là nguyên nhân hở hai bên); mỗi trang tự giới hạn cột thân (VPageScaffold 720, Trợ lý 840…),
   trang không có cột riêng dùng --sh-col-gutter để thân rộng tối đa 1120 canh giữa. */
.sh-content { flex: 1; min-height: 0; width: 100%; display: flex; flex-direction: column; --sh-col-max: 1120px; }

.sh-side { flex: 0 0 84px; width: 84px; display: flex; flex-direction: column; align-items: stretch; gap: 4px; min-height: 0; padding: 16px 8px; background: #FFFFFF /*surface-default*/; border-right: 1px solid #E5E8EB /*border-default*/; }
.sh-side__org { align-self: center; display: grid; place-items: center; width: 40px; height: 40px; margin-bottom: 16px; padding: 0; border: 0; border-radius: 8px; background: #2F7A3A /*action-primary-default*/; color: #FFFFFF /*action-on-primary*/; font-size: 16px; font-weight: 700; cursor: pointer; }
.sh-side__org .icon { font-size: 20px; }
.sh-side__org:hover { background: #1F4D26 /*action-primary-pressed*/; }
.sh-side__tab { display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 4px; min-height: 60px; padding: 8px 2px; border: 0; border-radius: 8px; background: transparent; color: #4A535E /*text-secondary*/; font-size: 11px; line-height: 14px; font-weight: 600; text-align: center; cursor: pointer; }
.sh-side__tab .icon { font-size: 22px; }
.sh-side__tab:not(.is-on):hover { background: #F1F3F5 /*neutral-150*/; color: #0E1116 /*text-primary*/; }
.sh-side__tab.is-on { background: #EBF4EE /*surface-brand*/; color: #26612F /*text-brand*/; font-weight: 700; }
.sh-side__tab.is-on .icon { color: #2F7A3A /*action-primary-default*/; }
.sh-side__logout { color: #B53232 /*text-danger*/; }
.sh-side__tab:focus-visible, .sh-side__org:focus-visible { outline: 2px solid #2F7A3A /*focus-ring*/; outline-offset: 2px; }
.sh-side__spacer { flex: 1; }
.sh-side__manage { anchor-name: --sh-manage; }
.sh-side__menu { position-anchor: --sh-manage; inset: auto; left: anchor(right); bottom: anchor(bottom); width: 320px; margin-left: 12px; } /* margin-left bị .sh-menu { margin: 0 } đè → khe thực tế 0 (Q3) */

/* Menu nổi (popover ở top layer, nên tự đặt font / box-sizing) */

.sh-menu { margin: 0; padding: 8px; border: 1px solid #E5E8EB; border-radius: 12px; background: #FFFFFF; color: #0E1116; font-family: Inter,system-ui,-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif; font-size: 14px; box-shadow: 0 4px 12px rgb(14 17 22 / .08), 0 16px 40px rgb(14 17 22 / .12); }
.sh-menu, .sh-menu * { box-sizing: border-box; }
.sh-menu .icon { width: 1em; height: 1em; }
.sh-menu__title { margin: 0; padding: 8px 12px 4px; font-size: 12px; line-height: 16px; font-weight: 600; color: #4A535E /*text-secondary*/; }
.sh-menu__item { display: flex; align-items: center; gap: 12px; width: 100%; min-height: 44px; padding: 4px 12px; border: 0; border-radius: 8px; background: transparent; color: #0E1116 /*text-primary*/; font-family: inherit; text-align: left; cursor: pointer; }
.sh-menu__item:not(:disabled):not(.is-on):hover { background: #F1F3F5; }
.sh-menu__item.is-on { background: #EBF4EE; color: #26612F; }
.sh-menu__item.is-on .sh-menu__icon { color: #2F7A3A /*action-primary-default*/; }
.sh-menu__item:disabled { opacity: 0.4; cursor: default; }
.sh-menu__item:focus-visible { outline: 2px solid #2F7A3A; outline-offset: -2px; }
.sh-menu__icon { display: grid; place-items: center; flex: 0 0 auto; font-size: 18px; color: #4A535E /*text-secondary*/; }
.sh-menu__text { flex: 1; min-width: 0; display: flex; flex-direction: column; }
.sh-menu__text b { font-size: 14px; line-height: 20px; font-weight: 600; }
.sh-menu__text small { font-size: 12px; line-height: 16px; font-weight: 500; color: #4A535E /*text-secondary*/; }
```

### Ánh xạ phần tử → Flutter

| Prototype | Flutter |
|---|---|
| `.sh-side` 84, đệm 16 / 8, khe 4, nền, viền phải | `VSideNavigation(width: 84)`: `Container(width, color: surface, border right VBorders.side(borderDefault))` → `Padding(EdgeInsets.symmetric(vertical: VSpacing.space4, horizontal: VSpacing.space2))` → `Column(stretch)`, khe `SizedBox(height: VSpacing.space1)` |
| `.sh-side__org` 40×40, bo 8, nền primary, chữ 16/700 `textInverse`, hover `primaryPressed`, dưới 16; bị chặn → icon `store` 20 | ERP `_SideNavOrgTile` truyền vào `header`: `Center(SizedBox.square(40))`, `VRadius.r8`, `colors.primary` / hover `colors.primaryPressed`, `VTypography.headingH4.copyWith(fontSize: 16, fontWeight: w700, color: textInverse)`, `VIcon(VIcons.store, size: 20)`; `Tooltip(message: orgName)`; `Semantics(button, label: 'Đổi tổ chức, $orgName')`; đệm dưới `VSpacing.space4` |
| `.sh-side__tab` cột, icon 22, khe 4, cao ≥ 60, đệm 8/2, bo 8, chữ 11/14 600 `textSecondary` | `_RailTab`: `ConstrainedBox(minHeight: 60)`, `Padding(EdgeInsets.symmetric(vertical: VSpacing.space2, horizontal: 2))`, `IconTheme(size: 22)`, `SizedBox(height: VSpacing.space1)`, `Text(VTypography.labelSmall.copyWith(height: 14 / 11))`, `maxLines: 1`, `textAlign: center`, `MediaQuery.withClampedTextScaling(maxScaleFactor: 1.3)` |
| hover tab (không chọn): nền neutral-150, chữ `textPrimary` | `InkWell(hoverColor: colors.surfaceHoverStrong)` + đổi màu chữ khi hover (`onHover` → state) |
| `.is-on`: nền `surfaceBrand`, chữ `textBrand` 700, icon `primary` | như cột trái |
| `.sh-side__logout` chữ + icon `danger` | `VSideNavigationAction(icon: VIcons.logout, label: 'Đăng xuất', destructive: true)` → màu `colors.danger` |
| focus 2px `focus-ring` | viền `colors.primary`, `VBorders.thick` (như hiện tại) |
| `.sh-side__spacer` | `Spacer()` giữa tab cuối và mục có `children` |
| `.sh-menu` 320, đệm 8, viền, bo 12, bóng hai lớp | `_ManageMenu`: `Container(width: 320, padding: VSpacing.space2, borderRadius: VRadius.r12, border: VBorders.side(borderDefault), color: surface, boxShadow: [BoxShadow(0x140E1116, blur 12, offset (0,4)), BoxShadow(0x1F0E1116, blur 40, offset (0,16))])` |
| neo menu: trái = mép phải nút, đáy = đáy nút, khe 0 | Q3 |
| `.sh-menu__title` 12/16 600 `textSecondary`, đệm 8 12 4 | `Text(menuTitle, VTypography.caption.copyWith(height: 16 / 12))`, `EdgeInsets.fromLTRB(VSpacing.space3, VSpacing.space2, VSpacing.space3, VSpacing.space1)` |
| `.sh-menu__item` hàng, khe 12, cao ≥ 44, đệm 4/12, bo 8 | `_MenuItem`: `ConstrainedBox(minHeight: VSpacing.minTouchTarget)`, `EdgeInsets.symmetric(vertical: VSpacing.space1, horizontal: VSpacing.space3)`, `VRadius.r8` |
| `.sh-menu__icon` 18 `textSecondary` (chọn: `primary`) | `IconTheme(size: 18)` |
| `b` 14/20 600; `small` 12/16 500 `textSecondary` | `VTypography.labelDefault`; `VTypography.caption.copyWith(height: 16 / 12, fontWeight: w500, color: textSecondary)` |
| `.is-on` nền `surfaceBrand`, chữ `textBrand` | như cột trái; `Semantics(selected: true)` |
| `:disabled` mờ 0.4 | `vDisabledOpacity(enabled: …)`, `onTap: null` |

Icon mục con lấy từ `MoreEntry.icon` (đã có ở `more_entries.dart`); ERP truyền `VSideNavigationItem(icon: VIcon(icon: sub.icon), label: sub.title, description: sub.subtitle, …)`.

## Review Focus

1. **Bấm "Quản lý" khi đang mở menu** → đóng menu (bật / tắt), không mở hai lớp. Test ở Task 2.
2. **Chọn tổ chức khác trong lúc menu mở** (session đổi, danh sách mục con đổi) → menu đóng hoặc vẽ lại đúng danh sách mới, không giữ chỉ số cũ. Test ở Task 3 (`menu closes when tenant changes`).
3. **Thu cửa sổ < 1024 khi menu đang mở** → thanh biểu tượng biến mất, menu không treo trên màn (overlay phải gỡ cùng widget). Test ở Task 2 (`menu removed when rail unmounted`).
4. **Tên tổ chức bắt đầu bằng khoảng trắng hoặc chữ thường có dấu** (`" đại lý…"`) → chữ cái đầu là `Đ` (trim + `toUpperCase`). Test ở Task 3.
5. **Chữ phóng 1.3 ở nhãn dài nhất ("Đăng xuất", "Sản phẩm")** → không tràn 84 (1 dòng, `…`). Test ở Task 2.

---

### Task 0: Test giữ hành vi trên code cũ

**Files:**
- Modify: `apps/erp/test/features/dashboard/presentation/store_shell_test.dart`
- Modify: `packages/c45_design_system/test/components/v_side_navigation_test.dart`

**Interfaces:**
- Consumes: `createTestRouter` (cùng file), `FakeSessionRepository`.
- Produces: 8 test ERP + 3 test DS mới dưới đây; phải xanh **trước** khi sửa code và còn xanh sau Task 3 (được đổi cách tìm widget trong test — ví dụ mở menu "Quản lý" trước khi tìm "Kho" — không đổi điều kiện kiểm).

- [ ] **Step 1: Viết test trên code cũ**

```dart
testWidgets('blocked session at 1280: org header label "Đổi tổ chức, Chưa chọn tổ chức"', …
  expect(find.bySemanticsLabel('Đổi tổ chức, Chưa chọn tổ chức'), findsOneWidget);
testWidgets('staff at 1280: no "Người dùng & vai trò" sub-entry', …   // isOwner: false
  expect(find.text('Người dùng & vai trò'), findsNothing);
testWidgets('blocked at 1280: "Kho" disabled, "Tài khoản của tôi" enabled', …
  // Semantics của mục: enabled false / true
testWidgets('tap org header opens tenant selector', …
  // sau tap: tìm thấy tiêu đề sheet/dialog chọn tổ chức (VAdaptiveSheet) — dùng tiêu đề thật trong select_organization_bottom_sheet.dart
testWidgets('tap "Đăng xuất" signs out', …
  // FakeSessionRepository: kiểm cờ / bộ đếm signOut (thêm vào fake nếu chưa có)
testWidgets('tap sub-entry "Kho" goes to /warehouse', …
  // thêm GoRoute '/warehouse' vào createTestRouter (nhánh more) → 'WAREHOUSE_PAGE'
testWidgets('1280 on /orders: content width ≤ 1120', …
  // trang giả trong createTestRouter bọc SizedBox.expand(key: ValueKey('page-<path>')); expect(tester.getSize(find.byKey(...)).width, lessThanOrEqualTo(1120))
testWidgets('1280 on /more/my-account: content width ≤ 1120', …) // route không qua ErpTabScaffold
```

DS (`v_side_navigation_test.dart`, dùng `pumpNav` sẵn có):

```dart
testWidgets('has surface background and right hairline', …)    // BoxDecoration: color == surface, border.right.color == borderDefault
testWidgets('every item is at least 44 tall', …)                // mọi mục bấm được: height >= VSpacing.minTouchTarget
testWidgets('labels stay on one line under text scale 2.0', …)  // MediaQuery(textScaler: TextScaler.linear(2)): takeException() == null; mọi Text nhãn maxLines == 1
```

- [ ] **Step 2: Chạy, phải xanh trên code cũ**

Run: `cd apps/erp && flutter test test/features/dashboard/presentation/store_shell_test.dart` và `cd packages/c45_design_system && flutter test test/components/v_side_navigation_test.dart`
Expected: PASS toàn bộ (ghi tên 11 test vào mục Kết quả). Ở Task 2 / 3 chỉ được đổi cách dựng (mở menu trước khi tìm mục con), không đổi điều kiện kiểm.

- [ ] **Step 3: Commit**

```bash
git add apps/erp/test/features/dashboard/presentation/store_shell_test.dart apps/erp/test/core/session/fake_session_repository.dart packages/c45_design_system/test/components/v_side_navigation_test.dart
git commit -m "test(10-8a): test giữ hành vi thanh bên trước khi đổi"
```

### Task 1: Token `neutral150` + `surfaceHoverStrong`, icon `layers`

**Files:**
- Modify: `packages/c45_design_system/lib/src/tokens/v_colors.dart` (sau `neutral100`)
- Modify: `packages/c45_design_system/lib/src/theme/v_color_scheme.dart` (trường, constructor, `light`, `dark`, `copyWith`, `lerp`)
- Modify: `packages/c45_design_system/lib/src/foundations/icons/v_icons.dart` (enum + `_Lucide.layers = IconData(58665, fontFamily: 'Lucide', fontPackage: 'lucide_icons_flutter')` + `case`)
- Test: `packages/c45_design_system/test/tokens/` (file token màu hiện có) hoặc tạo `test/theme/v_color_scheme_hover_strong_test.dart`

**Interfaces:**
- Produces: `VColors.neutral150` (`Color(0xFFF1F3F5)`), `VColorScheme.surfaceHoverStrong` (light `VColors.neutral150`, dark `VColors.neutral500`), `VIcons.layers`.

- [ ] **Step 1: Test hỏng**

```dart
test('neutral150 khớp tokens.css', () => expect(VColors.neutral150, const Color(0xFFF1F3F5)));
test('surfaceHoverStrong sáng = neutral150', () => expect(VColorScheme.light.surfaceHoverStrong, VColors.neutral150));
test('lerp giữ surfaceHoverStrong', () => expect(VColorScheme.light.lerp(VColorScheme.light, .5).surfaceHoverStrong, VColors.neutral150));
testWidgets('VIcons.layers vẽ được', …) // VIcon(icon: VIcons.layers) không ném
```

- [ ] **Step 2: Chạy → FAIL** (`neutral150` chưa có)

Run: `cd packages/c45_design_system && flutter test test/theme test/tokens`

- [ ] **Step 3: Thêm token / trường / icon**

- [ ] **Step 4: Chạy lại → PASS; chạy `python3 packages/c45_design_system/tool/check_prototype_tokens.py` (từ gốc repo) → không còn báo lệch `neutral-150`**

- [ ] **Step 5: Commit** `feat(ds): neutral150, surfaceHoverStrong, VIcons.layers (10-8a)`

### Task 2: `VSideNavigation` thành thanh biểu tượng + menu nổi

**Files:**
- Modify: `packages/c45_design_system/lib/src/components/v_side_navigation.dart` (viết lại)
- Modify: `packages/c45_design_system/test/components/v_side_navigation_test.dart`
- Modify: `packages/c45_design_system/example/lib/preview/components_tab.dart:1718-1780` (mô tả "Thanh biểu tượng web 84, 4 tab, Quản lý mở menu, Đăng xuất")
- Modify: `packages/c45_design_system/CHANGELOG.md`, `pubspec.yaml` (`1.7.0` → `1.8.0` bằng `scripts/bump_version.sh`)
- Modify: `DESIGN.md` (frontmatter dòng 164 `width: "240px"` → `"84px"`; mục Navigation dòng 322 viết lại theo bảng ánh xạ; dòng 325 "≥ 1080px khi có thanh bên 240px" → "≥ 924px khi có thanh biểu tượng 84px, tức mọi khổ desktop")

**Interfaces:**
- Consumes: Task 1 (`surfaceHoverStrong`, `VIcons.layers` không dùng trực tiếp trong DS — icon do app truyền).
- Produces:

```dart
class VSideNavigationItem {
  const VSideNavigationItem({this.icon, required this.label, this.description, this.menuTitle, this.enabled = true, this.children = const []});
  final Widget? icon; final String label; final String? description; final String? menuTitle;
  final bool enabled; final List<VSideNavigationItem> children;
}
class VSideNavigation extends StatelessWidget {   // có thể StatefulWidget nội bộ cho OverlayPortalController
  const VSideNavigation({super.key, required this.items, required this.selected, required this.onSelect, this.header, this.footer, this.width = 84});
}
class VSideNavigationAction extends StatelessWidget {
  const VSideNavigationAction({super.key, required this.icon, required this.label, required this.onTap, this.destructive = false});
  final VIcons icon; final String label; final VoidCallback onTap; final bool destructive;
}
```

Bố cục: `header` → tab của các mục **không** có `children` (theo thứ tự) → `Spacer` → tab của mục **có** `children` → `footer`. Chọn: tab sáng khi `selected.$1 == i`; mục con sáng khi `selected == (i, c)`. Bấm tab có `children` → bật / tắt menu (Q3, Q4); bấm mục con → `onSelect(i, c)` rồi đóng menu. Nhãn trên tab là `label`; tiêu đề menu là `menuTitle ?? label`.

- [ ] **Step 1: Viết lại test DS** (giữ 7 test cũ + 3 test Task 0, chỉ đổi cách dựng: `width` mặc định 84, mở menu bằng tap tab "Thêm" trước khi tìm mục con; thêm test mới):

```dart
testWidgets('rail is 84 wide with right hairline', …) // tester.getSize(find.byType(VSideNavigation)).width == 84
testWidgets('item with children sits below spacer and opens menu', …)
  // dy của 'Thêm' > dy của 'Đơn hàng' + 100 (nằm đáy); trước tap: find.text('Kho') findsNothing; sau tap: findsOneWidget; find.text(menuTitle) findsOneWidget
testWidgets('tapping parent does not call onSelect; tapping it again closes menu', …)
testWidgets('tap child calls onSelect(2, 0) and closes menu', …)
testWidgets('Escape and outside tap close menu', …)
testWidgets('parent with selected child is highlighted', …) // selected (2, 1): nền tab 'Thêm' == surfaceBrand; mở menu: mục 'Thiết lập' Semantics selected true
testWidgets('menu shows description under child label', …) // description: 'Tồn kho, phiếu nhập, điều chỉnh'
testWidgets('tab min height 60, menu item min height 44', …)
testWidgets('label clamps text scale to 1.3 and stays on one line', …) // MediaQuery textScaler 2.0: không overflow (tester.takeException() == null), Text.maxLines == 1
testWidgets('menu removed when rail unmounted', …) // mở menu, pumpWidget SizedBox → find.text('Kho') findsNothing, không exception
testWidgets('VSideNavigationAction destructive uses danger color', …)
```

- [ ] **Step 2: Chạy → FAIL** (`description`, `VSideNavigationAction` chưa có)

Run: `cd packages/c45_design_system && flutter test test/components/v_side_navigation_test.dart`

- [ ] **Step 3: Viết lại `v_side_navigation.dart`** theo bảng ánh xạ; tab có `hover` đổi chữ sang `textPrimary` khi không chọn; viền focus `colors.primary` `VBorders.thick`; giữ `vInspectorHide`, `MergeSemantics`, `vDisabledOpacity`.

- [ ] **Step 4: Chạy → PASS**; `cd packages/c45_design_system && dart analyze lib test example`

- [ ] **Step 5: Cập nhật preview, CHANGELOG (mục `[1.8.0]`: Changed `VSideNavigation` → thanh biểu tượng 84 + menu nổi; Added `VSideNavigationItem.description/menuTitle`, `VSideNavigationAction`, `VColors.neutral150`, `VColorScheme.surfaceHoverStrong`, `VIcons.layers`), bump `1.8.0`, `DESIGN.md`**

- [ ] **Step 6: Commit** `feat(ds): VSideNavigation thành thanh biểu tượng 84 + menu nổi (10-8a)`

### Task 3: ERP — `ErpSideNavigation`, bề ngang khung, ảnh Flutter

**Files:**
- Modify: `apps/erp/lib/features/dashboard/presentation/widgets/erp_side_navigation.dart` (thay `_SideNavHeader` bằng `_SideNavOrgTile`; `_SideNavFooter` bằng `VSideNavigationAction`)
- Modify: `apps/erp/lib/features/dashboard/presentation/store_shell.dart:150-172` (Q1; sửa doc comment dòng 21-24)
- Modify: `apps/erp/test/features/dashboard/presentation/store_shell_test.dart`
- Create: `apps/erp/test/features/dashboard/presentation/shell_golden_test.dart`
- Create (ảnh): `docs/refactor/plans/P10/img/10-8a/flutter-shell-*.png` (10 ảnh khớp bảng Ảnh)

**Interfaces:**
- Consumes: Task 2 (`VSideNavigationItem.description/menuTitle`, `VSideNavigationAction`), Task 1 (`VIcons.layers`).
- Produces: `ErpSideNavigation` giữ chữ ký `({Key? key, String? currentLocation})`.

Mục "Thêm" trên thanh: `VSideNavigationItem(icon: const VIcon(icon: VIcons.layers), label: 'Quản lý', menuTitle: 'Quản lý cửa hàng', children: …)` — chỉ thanh web đổi nhãn; `ErpTab.more.label` ('Thêm') giữ cho thanh dưới. `VSideNavigation` nhận `key: ValueKey(sessionState.current?.tenantId)` để đổi tổ chức thì dựng lại và gỡ menu đang mở (Review Focus 2). Chữ cái đầu: `orgName.trim().isEmpty || isBlocked ? icon store : orgName.trim().characters.first.toUpperCase()`.

`StoreShell._buildLayout` desktop: `Expanded(child: isHome ? content : VContentWidth(child: content))` với `isHome = GoRouterState.of(context).matchedLocation == '/'` (đọc trong `LayoutBuilder`, như `ErpSideNavigation` đang làm).

- [ ] **Step 1: Sửa / thêm test**
  - 8 test ERP của Task 0: chỉ đổi cách tìm (mở menu bằng tap `'Quản lý'` trước khi tìm mục con). "wide 1280 … tab navigation works" vẫn kiểm `selected == (4, 4)`.
  - Mới:

```dart
testWidgets('1280: rail has no "Thêm", has "Quản lý" and "Đăng xuất"', …)
testWidgets('1280 on /: content width 1196 (không bó)', …) // 1280 − 84
testWidgets('1280 blocked on /: notice spans full content width', …) // OrganizationEmptyView rộng > 1120
testWidgets('org tile initial: " đại lý Minh Tâm" → "Đ"', …)
testWidgets('menu closes when tenant changes', …) // mở menu, đổi state SessionController sang tenant khác → find.text('Quản lý cửa hàng') findsNothing
testWidgets('900 wide: bottom bar 5 tabs incl. "Thêm", no rail', …)
```

  - `warehouse_hub_routes_test.dart:36` vẫn `find.byType(ErpSideNavigation)` → không đổi.

- [ ] **Step 2: Chạy → FAIL** ở test mới

Run: `cd apps/erp && flutter test test/features/dashboard/presentation test/features/inventory/presentation/hub/warehouse_hub_routes_test.dart`

- [ ] **Step 3: Sửa 3 file lib theo trên**

- [ ] **Step 4: Chạy → PASS**

- [ ] **Step 5: Golden** — `shell_golden_test.dart` dựng `createTestRouter`-tương tự (trang giả là `ColoredBox(surfaceAlt)` có tiêu đề `VAppBar` như prototype "Kho" / ô giữ chỗ), `useInventoryTestSurface`, `RepaintBoundary`, đường dẫn `${repoRoot()}/docs/refactor/plans/P10/img/10-8a/flutter-shell-<ca>-<rộng>.png` (khuôn `test/features/receivable/presentation/receivable_golden_test.dart:110-136`). 10 ca theo bảng Ảnh; ca menu mở: tap `'Quản lý'` rồi `pump(400ms)`.

Run: `cd apps/erp && flutter test --update-goldens test/features/dashboard/presentation/shell_golden_test.dart` rồi chạy lại không `--update-goldens` → PASS. So từng cặp ảnh với cột Prototype; lệch ghi ở mục Kết quả.

- [ ] **Step 6: Kiểm phạm vi**

Run: `cd apps/erp && dart analyze lib test && dart run tool/check_feature_imports.dart`
Expected: không lỗi mới; check imports OK.

- [ ] **Step 7: Commit** `feat(10-8a): thanh biểu tượng web + Quản lý, khung không bó Trang chủ`

### Task 4: Tài liệu tiến độ

**Files:**
- Modify: `docs/refactor/PLAN.md` (bảng "Khung chung" dòng "Layout tổng thể": cột "Chuyển về Flutter" ✅ ngày, Ghi chú thêm link plan)
- Modify: `specs/prototype/shell/html/README.md` (mục "Đề xuất đã chốt…": thêm "Đã có trong Flutter (10-8a)"; phát hiện 4 sửa theo Q1; **phát hiện 1 sai**: `/more/receivables`, `/pricing`, `/more/settings`, `/more/users-and-roles`, `/more/my-account` nằm trong `ShellRoute(StoreShell)` (đóng ở `app_router.dart:1234`) nên web **có** thanh bên, chỉ iPhone mất thanh dưới vì không qua `ErpTabScaffold` — sửa câu trong README; hàm `insideShell` ở `shared/shell.js:50-61` chỉ thêm chú thích, không đổi (đổi hàm làm đổi ảnh mọi theme, người dùng quyết))
- Modify: `docs/refactor/CHECKLIST.md` (tick "Mới" APP-04 nếu kiểm tay đạt — người dùng kiểm)

- [ ] **Step 1: Cập nhật 3 file**
- [ ] **Step 2: Commit** `docs(10-8a): cập nhật tiến độ khung chung`

## Kết quả

**Task 0 (code cũ, xanh trước khi sửa):** ERP (`store_shell_test`, 17/17 lúc đó) — `blocked session at 1280: org header label …`, `staff at 1280: no "Người dùng & vai trò" sub-entry`, `blocked at 1280: "Kho" disabled, "Tài khoản của tôi" enabled`, `tap org header opens tenant selector`, `tap "Đăng xuất" signs out`, `tap sub-entry "Kho" goes to /warehouse`, `1280 on /orders: content width ≤ 1120`, `1280 on /more/my-account: content width ≤ 1120`. DS (`v_side_navigation_test`, 10/10) — `has surface background and right hairline`, `every item is at least 44 tall`, `labels stay on one line under text scale 2.0`.

**Lệnh sau khi sửa:**
- DS: `flutter test test/components/v_side_navigation_test.dart test/components/accessibility_guidelines_test.dart test/theme test/tokens` → 93/93 xanh; `check_prototype_tokens.py` hết lệch `neutral-150` (còn dòng "khác khái niệm focus-ring" có sẵn).
- ERP: `store_shell_test` 23/23, `shell_golden_test` 10/10 (chạy `--update-goldens` rồi chạy lại xanh), `warehouse_hub_routes_test` xanh; `dart analyze` file đã sửa sạch; `check_feature_imports` 91 dòng như trước khi sửa, không có dòng nào ở `dashboard`.
- DS bump `1.7.0` → `1.8.0` (script `--set 1.8.0`, cắt cả mục Unreleased có sẵn).

**Rulings:**
- Viền focus của tab / mục menu vẽ bằng `foregroundDecoration` luôn có mặt (trong suốt khi không focus): đổi null ↔ giá trị làm đổi cây widget và mất focus bàn phím.
- `VIcon` bỏ qua `IconTheme` nên DS dựng lại `VIcon` với cỡ / màu theo trạng thái (`_styledIcon`); icon không phải `VIcon` dùng `IconTheme`.
- Test T0 tìm trạng thái bật / tắt bằng `Semantics.properties.enabled` thay vì `SemanticsNode.flags` (nhãn "Đổi tổ chức…" cũng tìm bằng `Semantics.properties.label`), vì nhãn bị gộp với chữ con.
- Test đăng xuất đăng ký `SessionController` riêng vào `getIt` (hàm `signOutAndGoToLogin` đọc từ `getIt`, còn `StoreShell` test dựng controller riêng).

**Lệch ảnh:** golden dựng bằng font Ahem (test không nạp font) nên chữ và icon là ô vuông; chỉ so được hình học. Kích thước, vị trí tab, menu (mép trái ≈ 76, đáy menu trùng đáy nút "Quản lý"), ô tổ chức 40, tab "Đăng xuất" ở đáy khớp ảnh `proto-*`. Chưa so được màu chữ / icon thật — người dùng kiểm tay trên máy (APP-04 chưa tick CHECKLIST).

## Review

_(phiên review ghi)_
