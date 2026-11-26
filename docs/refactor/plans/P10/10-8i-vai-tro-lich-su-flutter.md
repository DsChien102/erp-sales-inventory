# 10-8i Vai trò, Lịch sử quản trị — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** ID-19 Vai trò và ID-20 Lịch sử quản trị có bố cục iPhone và web đúng prototype Theme 1 (web bảng toàn màn, chi tiết toàn màn); sửa lỗi 8 (bộ lọc), 12, 13, 14; sửa kèm 13 lỗi thấy khi đọc code (Q5–Q17).

**Architecture:** `RolesAreaShell`, `AuditAreaShell` giữ ShellRoute và cubit, thôi chia cột. Trang giữ cubit, điều hướng (`go` ở web, `push` ở hẹp); bố cục `Narrow` / `Wide` dùng `AdminTable` (10-8h), `detail_layout.dart` (10-8g). Khoảng thời gian lọc là một giá trị (`TenantAuditRange`) trong `TenantAuditFilter`, cubit đổi sang mốc UTC.

**Tech Stack:** Flutter, flutter_bloc, go_router, `c45_design_system` 1.10.0.

**Spec:** bản thiết kế "10-8: Theme 1 về Flutter" duyệt trong chat 2026-11-25, phần chung ở [10-8d](10-8d-nen-theme1-flutter.md#thiết-kế-đã-duyệt-phần-chung-cho-10-8dk). Nguồn hình: `specs/themes/theme-01/03.design/prototype/html/app/{roles,audit}.js`, `app/web/{roles,audit}.js`. **Làm sau 10-8h.**

## Global Constraints

- Chữ, câu lỗi, RPC, route giữ nguyên, trừ điều ghi ở Quyết định. Không đổi SQL.
- Dữ liệu nhạy cảm vẫn che như hiện nay (`[Đã che theo chính sách]`); không hiện thêm trường thô nào.
- Chỉ Chủ sở hữu vào Vai trò, quyền `tenant.audit.view` vào Lịch sử: giữ kiểm ở router.
- Màu `context.vColors` / `VColors`, `VSpacing`, `VRadius`, `VTypography`.
- Chỉ chạy test liệt kê ở từng task; **không** chạy `flutter test` toàn app.

## Quyết định

| # | Quyết định | Lý do |
|---|---|---|
| Q1 | **Lỗi 8:** tiêu đề sheet "Bộ lọc lịch sử quản trị" | Bỏ chữ "nền tảng" |
| Q2 | **Lỗi 12:** `enum TenantAuditRange { h24, d7, d30 }`. `d7` / `d30` = hôm nay và 6 / 29 ngày trước (ngày Việt Nam); `h24` = từ đúng 24 giờ trước (mốc chốt lúc tìm lại, giữ nguyên khi "Tải thêm"). Phụ đề: "n hoạt động trong 24 giờ" / "trong 7 ngày" / "trong 30 ngày". "Đặt lại" về `d30`, kết quả "Tất cả". Mở lại sheet đúng lựa chọn cũ | "24 giờ" đang thành hai ngày, sheet mở lại thành "30 ngày", "Đặt lại" về 24 giờ |
| Q3 | **Lỗi 13:** bỏ nhóm "Loại chủ thể" khỏi sheet và `AuditLogFilterCriteria.actorType` | TH-01 không có, RPC không có tham số |
| Q4 | **Lỗi 14:** Vai trò đang tải: hẹp `VLoading` giữa màn, phụ đề "Đang tải vai trò"; web khung xương 4 dòng, cùng phụ đề | Đang hiện "0 vai trò hệ thống" |
| Q5 | **Sửa kèm:** chi tiết vai trò lỗi tải → khối lỗi như danh sách + "Thử lại" | Đang là chữ trần, không thử lại được (US-07.1 AC-01) |
| Q6 | **Sửa kèm:** ngày hiện tại lấy `VDateTime.toIct(clock())`, không lấy giờ máy; cubit tính khoảng, trang không gọi `DateTime.now()` | Máy khác múi giờ lệch một ngày; test không kiểm được |
| Q7 | **Sửa kèm:** lọc 24 giờ / 7 ngày không ra kết quả → "Không có hoạt động phù hợp" + "Xóa bộ lọc" (`hasAdvancedFilters` tính cả khoảng ≠ `d30`) | Đang hiện "Chưa có hoạt động quản trị" |
| Q8 | **Sửa kèm:** "Xóa bộ lọc" huỷ lần tìm đang chờ (`_debounce`) và xoá ô tìm | Chữ vừa gõ có thể lọc lại sau 350 ms |
| Q9 | **Sửa kèm:** trả lời cũ bị bỏ (số thứ tự mỗi lần `search`) | Đổi chip nhanh thì kết quả cũ ghi đè |
| Q10 | **Sửa kèm:** "Tải thêm" lỗi → toast "Không tải thêm được" + câu lỗi, giữ danh sách (kể cả mã không quyền) | Đang im lặng, hoặc thay cả màn khi không quyền |
| Q11 | **Sửa kèm:** mở chi tiết chỉ gọi `get_tenant_audit_log` **một** lần (bỏ `..loadDetail` ở `create`, giữ trong `initState`) | Đang gọi hai lần |
| Q12 | **Sửa kèm:** chi tiết lỗi: mã `resourceNotFound` → "Không tìm thấy hoạt động" + câu TH-01; lỗi khác → "Không tải được hoạt động" + câu lỗi; cả hai có "Thử lại" | Mất mạng đang báo "Không tìm thấy" |
| Q13 | **Sửa kèm:** toast sao chép: "Đã sao chép mã theo dõi." | `VToast` chỉ hiện `message`, nên đang hiện cả mã |
| Q14 | **Sửa kèm:** chi tiết: "Loại chủ thể" → "Vai trò"; web "Thay đổi" → "Dữ liệu thay đổi"; "Nguồn: Tenant App" → "Ứng dụng"; "Audit ID" → "Mã nhật ký" | Nhãn sai nghĩa / tiếng Anh; TH-01 US-07.2 FR-03 |
| Q15 | **Sửa kèm:** danh sách hiện nhãn kết quả khi **không** phải "Thành công": "Bị chặn" (`warning`), "Lỗi" (`danger`), cạnh tên hoạt động. Chi tiết: nhãn theo đúng kết quả | US-07.2 FR-02 đòi có kết quả; prototype chỉ vẽ "Thành công" |
| Q16 | **Sửa kèm:** tìm theo tên hoạt động: khớp nguyên cụm như cũ, thêm khớp **một phần** (chứa, không phân biệt hoa thường, giữ dấu) khi chuỗi có từ hai từ trở lên | "tạm ngừng" đang không ra gì: RPC so tên người, tên đối tượng, mã sự kiện và `title_snapshot`, mà `title_snapshot` mặc định là mã sự kiện (`20260826004…sql:289`; không migration nào truyền tiêu đề riêng); app chỉ khớp nguyên tên. Một từ thì ưu tiên tìm người (tên "Thành" không bị hiểu là "thành viên") |
| Q17 | **Sửa kèm:** xoá `audit_log_list_content.dart` và `audit_log_filter_chips.dart` nếu không còn ai dùng (grep); cùng export | Code chết, có chữ "24 giờ" ghi cứng |
| Q18 | Hẹp gộp theo ngày Việt Nam, giờ `HH:mm`; web cột "Thời điểm" `dd/MM/yyyy HH:mm` | `audit.js:20-26` |
| Q19 | Vai trò: người giữ tối đa 3 ô chữ viết tắt + tên một dòng cắt "…"; không bấm được (không mở thành viên) | `roles.js:17-20` |
| Q20 | Chi tiết web: ← luôn có; hẹp dùng `VAppBar` chung thay `AppBar` Material | Prototype iPhone đã đổi 2026-11-25; web cũng dùng `VAppBar` để các trang cùng kiểu (ảnh web vẽ thanh không gạch — lệch chấp nhận) |

## Ảnh

Nguồn: `tools/proto-final/`, chép 2026-11-25; chụp lại ở Task 1 (`roles__loading`, `audit__filter`, `audit-detail__*`, ca mới `audit__blocked`). Cột Flutter: golden `img/10-8i/flutter-<ca>-{390,1280}.png`.

| Ca | 390 | 1280 |
|---|---|---|
| roles__list | ![](img/10-8i/proto-roles__list-390.png) | ![](img/10-8i/proto-roles__list-1280.png) |
| roles__loading | ![](img/10-8i/proto-roles__loading-390.png) | ![](img/10-8i/proto-roles__loading-1280.png) |
| roles__failed | ![](img/10-8i/proto-roles__failed-390.png) | ![](img/10-8i/proto-roles__failed-1280.png) |
| roles__detail | ![](img/10-8i/proto-roles__detail-390.png) | ![](img/10-8i/proto-roles__detail-1280.png) |
| roles__detail-empty | ![](img/10-8i/proto-roles__detail-empty-390.png) | ![](img/10-8i/proto-roles__detail-empty-1280.png) |
| audit__list | ![](img/10-8i/proto-audit__list-390.png) | ![](img/10-8i/proto-audit__list-1280.png) |
| audit__loading | ![](img/10-8i/proto-audit__loading-390.png) | ![](img/10-8i/proto-audit__loading-1280.png) |
| audit__no-results | ![](img/10-8i/proto-audit__no-results-390.png) | ![](img/10-8i/proto-audit__no-results-1280.png) |
| audit__forbidden | ![](img/10-8i/proto-audit__forbidden-390.png) | ![](img/10-8i/proto-audit__forbidden-1280.png) |
| audit__filter | ![](img/10-8i/proto-audit__filter-390.png) | ![](img/10-8i/proto-audit__filter-1280.png) |
| audit__filter-applied | ![](img/10-8i/proto-audit__filter-applied-390.png) | ![](img/10-8i/proto-audit__filter-applied-1280.png) |
| audit__blocked | ![](img/10-8i/proto-audit__blocked-390.png) | ![](img/10-8i/proto-audit__blocked-1280.png) |
| audit-detail__detail | ![](img/10-8i/proto-audit-detail__detail-390.png) | ![](img/10-8i/proto-audit-detail__detail-1280.png) |
| audit-detail__actor-unavailable | ![](img/10-8i/proto-audit-detail__actor-unavailable-390.png) | ![](img/10-8i/proto-audit-detail__actor-unavailable-1280.png) |
| audit-detail__not-found | ![](img/10-8i/proto-audit-detail__not-found-390.png) | ![](img/10-8i/proto-audit-detail__not-found-1280.png) |
| audit-detail__toast-copied | ![](img/10-8i/proto-audit-detail__toast-copied-390.png) | ![](img/10-8i/proto-audit-detail__toast-copied-1280.png) |

## Code prototype (chép nguyên văn, token thay bằng giá trị)

### ID-19

`app/roles.js:10-45`

```js
/** Mô tả hiển thị: bỏ ghi chú kỹ thuật trong ngoặc ở cuối (như bản web). */
const shortDesc = (d) => String(d).replace(/\s*\([^)]*\)\s*$/, '');

/**
 * Thẻ vai trò (iPhone, impeccable live 2026-11-25): tên + nhãn "Đang dùng" + mô tả + mũi tên (cả thẻ bấm được);
 * chân thẻ: người đang giữ (tối đa 3 ô tròn 28 + tên một dòng, dư cắt "…") hoặc câu chưa có ai.
 */
const holderAvatar = (n) => `<span class="t1-rolecard__av" aria-hidden="true">${esc(n.trim().split(/\s+/).pop()[0])}</span>`;
const roleCard = (r, selected) => `<button type="button" class="t1-rolecard"${selected ? ' aria-current="true"' : ''}>
  <span class="t1-rolecard__main"><span class="t1-rolecard__text"><span class="t1-rolecard__name"><b>${esc(r.title)}</b>${r.members.length ? badge('Đang dùng', 'success') : ''}</span><small>${esc(shortDesc(r.description))}</small></span>${icon('chevronRight', 't1-rolecard__go')}</span>
  <span class="t1-rolecard__foot">${r.members.length ? `${r.members.slice(0, 3).map(holderAvatar).join('')}<span class="t1-rolecard__who">${r.members.map(esc).join(', ')}</span>` : '<span class="t1-rolecard__who">Chưa có thành viên đang giữ vai trò này.</span>'}</span></button>`;

/** Không có nhánh "đang tải": khi chưa có dữ liệu vẫn vẽ phần đầu + "0 vai trò hệ thống" và danh sách rỗng. */
function rolesList(s, w, selected) {
  const roles = s.loading ? [] : ROLES;
  const body = s.failed
    ? `<div class="t1-center t1-pad-h"><div class="t1-card t1-rfail">
        <span class="t1-ring t1-ring--danger t1-ring--56">${icon('close')}</span><div class="t1-gap-md"></div>
        <h2 class="t1-h3 t1-danger t1-text-center">Không thể tải danh sách vai trò</h2><div class="t1-gap-xs"></div>
        <p class="t1-body2 t1-text-center">Dịch vụ phân quyền đang tạm thời không khả dụng. Vui lòng thử lại sau.</p><div class="t1-gap-md"></div>
        ${button('Thử lại', { variant: 'link' })}</div></div>`
    : `<div class="t1-list"><h2 class="t1-selrole__title">Vai trò hệ thống</h2><p class="t1-small t1-selrole__sub">Vai trò vận hành không thay đổi tư cách Chủ sở hữu.</p>
      <div class="t1-rolecards">${roles.map((r) => roleCard(r, r.id === selected)).join('')}</div></div>`;
  return vScaffold({ title: 'Vai trò', subtitle: s.failed ? 'Không tải được' : `${roles.length} vai trò hệ thống`, body, placeWidth: w, fixed: !!s.failed });
}

function roleDetail(code, w, split) {
  const r = ROLES.find((x) => x.id === code);
  // Bố cục iPhone thiết kế lại qua impeccable live (2026-11-25): ô khiên + tên + mô tả + "Vai trò hệ thống · Chỉ đọc" → thẻ thành viên (ô tròn 36 + tên, không bấm được).
  const holders = r.members.map((n) => `<div class="t1-roledet__row"><span class="t1-rolecard__av t1-roledet__av" aria-hidden="true">${esc(n.trim().split(/\s+/).pop()[0])}</span><b>${esc(n)}</b></div>`).join('');
  const body = `<div class="t1-list t1-roledet">
    <div class="t1-orgm__head"><div class="t1-orgm__icon" aria-hidden="true">${icon('shield')}</div><div><h2>${esc(r.title)}</h2><p>${esc(shortDesc(r.description))}</p><p class="t1-roledet__sys">${icon('lock')}Vai trò hệ thống · Chỉ đọc</p></div></div>
    <h3 class="t1-acc__title">Thành viên đang giữ vai trò</h3>
    ${card(holders || '<p class="t1-small t1-roledet__none">Chưa có thành viên đang giữ vai trò này.</p>', 't1-roledet__list')}</div>`;
  return vScaffold({ title: 'Chi tiết vai trò', back: !split, body, placeWidth: w });
}
```

`app/web/roles.js:7-42`

```js
/** Mô tả hiển thị: bỏ ghi chú kỹ thuật trong ngoặc ở cuối (vd. "(gán mặc định cho Owner…, BR-36)"). */
const shortDesc = (d) => String(d).replace(/\s*\([^)]*\)\s*$/, '');

function roleDetail(code, w) {
  const r = ROLES.find((x) => x.id === code);
  const body = `<div class="t1-list">${vcard(`<h2 class="t1-h4">${esc(r.title)}</h2><div class="t1-gap-xs"></div><p class="t1-small">${esc(shortDesc(r.description))}</p><div class="t1-gap-md"></div><p class="t1-small">Vai trò hệ thống · Chỉ đọc</p>`)}
    <div class="t1-gap-md"></div><h2 class="t1-h4">Thành viên đang giữ vai trò</h2><div class="t1-gap-sm"></div>
    ${r.members.length ? r.members.map((n) => `<p class="t1-bodyp t1-mb8">${esc(n)}</p>`).join('') : '<p class="t1-small">Chưa có thành viên đang giữ vai trò này.</p>'}</div>`;
  return vScaffold({ title: 'Chi tiết vai trò', body, placeWidth: w });
}

/**
 * Web (≥ 840) — bảng toàn màn, chọn qua impeccable live (2026-11-24): app bar "Vai trò · n vai trò hệ thống"; cột 1120: câu dẫn → bảng
 * (Vai trò hệ thống: tên + mô tả | Thành viên đang giữ vai trò: chữ viết tắt + tên). Bấm dòng mở chi tiết toàn màn (←). Đang tải: skeleton.
 */
function rolesTable(s) {
  const avatar = (n) => `<span class="t1-avatar" aria-hidden="true">${esc(n.trim().split(/\s+/).pop()[0])}</span>`;
  const holders = (r) => (r.members.length ? `<span class="t1-rholders">${r.members.map(avatar).join('')}<span>${r.members.map(esc).join(', ')}</span></span>` : '<span class="t1-rnone">Chưa có thành viên đang giữ vai trò này.</span>');
  const th = `<div class="t1-utable__tr t1-utable__th t1-rtable__tr" role="row"><span role="columnheader">Vai trò hệ thống</span><span role="columnheader">Thành viên đang giữ vai trò</span><span></span></div>`;
  let content;
  if (s.failed) {
    content = `<div class="t1-utable t1-utable--state"><div class="t1-uempty"><div class="t1-rfail">
      <span class="t1-ring t1-ring--danger t1-ring--56">${icon('close')}</span><div class="t1-gap-md"></div>
      <h2 class="t1-h3 t1-danger t1-text-center">Không thể tải danh sách vai trò</h2><div class="t1-gap-xs"></div>
      <p class="t1-body2 t1-text-center">Dịch vụ phân quyền đang tạm thời không khả dụng. Vui lòng thử lại sau.</p><div class="t1-gap-md"></div>
      ${button('Thử lại', { variant: 'link' })}</div></div></div>`;
  } else if (s.loading) {
    content = `<div class="t1-utable" role="table" aria-busy="true" aria-label="Đang tải">${th}${[0, 1, 2, 3].map(() => `<div class="t1-utable__tr t1-utable__tr--skel t1-rtable__tr"><span class="t1-skelcol">${skeleton({ w: 140, h: 16 })}${skeleton({ w: 220, h: 12 })}</span><span class="t1-rholders">${skeleton({ w: 28, h: 28, circle: true })}${skeleton({ w: 120 })}</span><span></span></div>`).join('')}</div>`;
  } else {
    content = `<div class="t1-utable" role="table" aria-label="Vai trò hệ thống">${th}
      ${ROLES.map((r) => `<button type="button" class="t1-utable__tr t1-rtable__tr" role="row"><span class="t1-rtable__role"><b>${esc(r.title)}</b><small>${esc(shortDesc(r.description))}</small></span><span>${holders(r)}</span>${icon('chevronRight', 't1-utable__chev')}</button>`).join('')}</div>`;
  }
  const sub = s.failed ? 'Không tải được' : s.loading ? '0 vai trò hệ thống' : `${ROLES.length} vai trò hệ thống`;
  return `<div class="t1-page t1-page--canvas">${appBar('Vai trò', { back: true, subtitle: sub })}
    <div class="t1-scroll"><div class="t1-uwrap"><p class="t1-small t1-rlead">Vai trò vận hành không thay đổi tư cách Chủ sở hữu.</p>${content}</div></div></div>`;
}
```

`styles/t1.css:307-319`

```css
/* ------------------------------------------------ Vai trò (iPhone, impeccable live 2026-11-25; web ở t1-web.css) */
.t1-rolecards { display: flex; flex-direction: column; gap: 8px; padding-bottom: 18px; }
.t1-rolecard { display: block; width: 100%; padding: 0; border: 1px solid #D0D5DA /*border-strong*/; border-radius: 12px /*radius-card*/; background: #FFFFFF /*surface-default*/; text-align: left; color: #0E1116 /*text-primary*/; cursor: pointer; }
.t1-rolecard:hover { background: #F8FAFB /*neutral-50*/; }
.t1-rolecard__main { display: flex; align-items: center; gap: 12px; min-height: 64px; padding: 10px 16px; }
.t1-rolecard__text { flex: 1; min-width: 0; display: flex; flex-direction: column; }
.t1-rolecard__name { display: flex; flex-wrap: wrap; align-items: center; gap: 2px 8px; }
.t1-rolecard__name b { font-size: 14px /*fs-md*/; line-height: 22px; font-weight: 600; }
.t1-rolecard__text small { font-size: 13px /*fs-sm*/; line-height: 20px; font-weight: 500; color: #4A535E /*text-secondary*/; }
.t1-rolecard__go { flex: none; font-size: 18px; color: #6B7480 /*icon-secondary*/; }
.t1-rolecard__foot { display: flex; align-items: center; gap: 8px; min-height: 44px; padding: 8px 16px; border-top: 1px solid #E5E8EB /*border-default*/; }
.t1-rolecard__av { display: grid; place-items: center; flex: none; width: 28px; height: 28px; border-radius: 999px /*radius-pill*/; background: #EBF4EE /*surface-brand*/; color: #26612F /*text-brand*/; font-size: 13px /*fs-sm*/; line-height: 16px; font-weight: 700; }
.t1-rolecard__who { min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; font-size: 13px /*fs-sm*/; line-height: 20px; font-weight: 500; color: #4A535E /*text-secondary*/; }
```

`styles/t1.css:390-399`

```css
/* ------------------------------------------------ Chi tiết vai trò (iPhone, impeccable live 2026-11-25; web ở web/roles.js) */
.t1-roledet .t1-orgm__head { align-items: flex-start; padding-bottom: 20px; }
.t1-roledet .t1-roledet__sys { display: flex; align-items: center; gap: 6px; margin-top: 2px; font-size: 13px /*fs-sm*/; line-height: 20px; }
.t1-roledet__sys .icon { font-size: 14px; color: #6B7480 /*icon-secondary*/; }
.t1-roledet__list { overflow: hidden; }
.t1-roledet__row { display: flex; align-items: center; gap: 12px; min-height: 56px; padding: 8px 16px; }
.t1-roledet__row + .t1-roledet__row { border-top: 1px solid #E5E8EB /*border-default*/; }
.t1-roledet__row b { min-width: 0; overflow-wrap: anywhere; font-size: 14px /*fs-md*/; line-height: 22px; font-weight: 600; color: #0E1116 /*text-primary*/; }
.t1-roledet__av { width: 36px; height: 36px; font-size: 15px; line-height: 18px; }
.t1-roledet__none { padding: 16px; }
```

`styles/t1-web.css:146-156`

```css
/* Vai trò — web: bảng toàn màn (cùng .t1-utable với Người dùng). */
.t1-rlead { margin: 0 0 16px; }
.t1-rtable__tr { grid-template-columns: minmax(280px, 1.4fr) 1fr 24px; }
.t1-rtable__role { display: flex; flex-direction: column; gap: 2px; min-width: 0; }
.t1-rtable__role b { font-weight: 600; }
.t1-rtable__role small { font-size: 13px /*fs-sm*/; color: #4A535E /*text-secondary*/; }
.t1-rholders { display: flex; align-items: center; gap: 8px; min-width: 0; }
.t1-rholders .t1-avatar { width: 28px; height: 28px; font-size: 12px /*fs-xs*/; }
.t1-rholders > span:last-child { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.t1-rnone { font-size: 13px /*fs-sm*/; color: #6B7480 /*text-muted*/; }
```


### ID-20

`app/audit.js:16-103`

```js
/**
 * Dòng lịch sử (iPhone, impeccable live 2026-11-25): giờ 40 | tiêu đề w600 (+ nhãn "Thông tin hiện tại"), "người (vai trò)", "<loại đối tượng>: <tên>" | mũi tên.
 * Gộp theo ngày: tiêu đề ngày + một thẻ chứa các dòng trong ngày (giữ thứ tự mới nhất trước).
 */
const auditRow = (a, selected) => `<button type="button" class="t1-aday__row"${selected ? ' aria-current="true"' : ''}><span class="t1-aday__time">${esc(a.at.split(' ')[1])}</span><span class="t1-aday__text">
  <span class="t1-aday__name"><b>${esc(a.title)}</b>${a.legacy ? badge('Thông tin hiện tại', 'neutral') : ''}</span>
  <span>${esc(a.actorRole && a.actorRole !== '—' ? `${a.actor} (${a.actorRole})` : a.actor)}</span>
  <span>${esc(`${a.subjectType}: ${a.subject}`)}</span></span>${icon('chevronRight', 't1-aday__go')}</button>`;
const auditDays = (items, selected) => [...new Set(items.map((a) => a.at.split(' ')[0]))].map((d) => `<section class="t1-aday"><h2 class="t1-aday__title">${esc(d)}</h2>
  <div class="t1-aday__box">${items.filter((a) => a.at.startsWith(d)).map((a) => auditRow(a, a.id === selected)).join('')}</div></section>`).join('');

/** AuditLogEmptyView: Align(0, −0.75); đệm ngang 16; VCard đệm 24; vòng 64 + icon 28; khe 16; H3 w700; khe 8; bodyDefault; khe 16; link. */
const EMPTY = {
  empty: ['info', '', 'Chưa có hoạt động quản trị', 'Các thay đổi người dùng, vai trò và thiết lập sẽ được ghi lại tại đây.', 'Tải lại'],
  noResults: ['search', '', 'Không có hoạt động phù hợp', 'Thử thay đổi từ khóa hoặc bộ lọc đang áp dụng.', 'Xóa bộ lọc'],
  error: ['error', 'danger', 'Không thể tải lịch sử quản trị', 'Đã xảy ra lỗi khi tải dữ liệu. Vui lòng thử lại.', 'Thử lại'],
  forbidden: ['shield', 'warning', 'Bạn không có quyền xem lịch sử quản trị', 'Liên hệ Chủ sở hữu hoặc người có quyền quản trị để được cấp quyền.', 'Quay lại'],
};
export const auditEmpty = (k) => {
  const [ic, tone, title, desc, act] = EMPTY[k];
  return `<div class="t1-aempty"><div class="t1-card t1-oempty__card"><span class="t1-ring${tone ? ` t1-ring--${tone}` : ''}">${icon(ic)}</span><div class="t1-gap-md"></div>
    <h2 class="t1-h3 t1-text-center${tone === 'danger' ? ' t1-danger' : ''}">${esc(title)}</h2><div class="t1-gap-sm"></div><p class="t1-body2 t1-text-center">${esc(desc)}</p><div class="t1-gap-md"></div>${button(act, { variant: 'link' })}</div></div>`;
};

function auditList(s, selected) {
  const days = s.days || 30;
  const sub = s.forbidden ? 'Chưa được cấp quyền' : s.error ? 'Không tải được dữ liệu' : `${s.empty || s.noResults ? 0 : AUDIT_TOTAL} hoạt động trong ${days} ngày`;
  let items = AUDIT;
  if (s.category === 'Thành viên') items = AUDIT.filter((a) => ['a3', 'a5'].includes(a.id));
  let list;
  if (s.forbidden) list = auditEmpty('forbidden');
  else if (s.loading) list = centerLoading();
  else if (s.error) list = auditEmpty('error');
  else if (s.empty) list = auditEmpty('empty');
  else if (s.noResults) list = auditEmpty('noResults');
  else list = `<div class="t1-alist t1-alist--days">${auditDays(items, selected)}<div class="t1-more">${button('Tải thêm', { variant: 'secondary' })}</div></div>`;
  return `<div class="t1-page t1-page--canvas">${appBar('Lịch sử quản trị', { back: true, subtitle: sub })}
    <div class="t1-fixed"><div class="t1-utop"><div class="t1-utop__find">${searchBar('Tìm người thực hiện hoặc hoạt động', s.query || '')}${iconButton('tune', days !== 30 ? 'Bộ lọc (đang áp dụng)' : 'Bộ lọc', { size: 20, dot: days !== 30 })}</div>
    <div class="t1-utop__chips">${chipRow(['Tất cả', 'Thành viên', 'Vai trò', 'Tổ chức'], s.category || 'Tất cả')}</div></div>
    <div class="t1-ulistwrap"><p class="t1-small t1-atimem">Thời gian: ${days} ngày gần đây · Mới nhất trước</p>${list}</div></div></div>`;
}

/** AuditLogFilterBottomSheet (title "Bộ lọc nhật ký nền tảng"): đệm 16 / 16 / 16 / 24; nhóm w700 + khe 8 + VChip; khe 16; khe 24; Đặt lại | 12 | Áp dụng. */
export const auditFilter = () => {
  const g = (t, opts, sel) => `<div class="t1-fgroup t1-fgroup--8"><b>${esc(t)}</b><div class="t1-fwrap">${opts.map((o) => chip(o, { tone: o === sel ? 'primary' : 'neutral' })).join('')}</div></div>`;
  return `<div class="t1-fsheet">${g('Thời gian', ['24 giờ', '7 ngày', '30 ngày'], '30 ngày')}${g('Kết quả', ['Tất cả', 'Thành công', 'Bị chặn', 'Lỗi'], 'Tất cả')}${g('Loại chủ thể', ['Tất cả', 'Người dùng', 'Hệ thống'], 'Tất cả')}
    <div class="t1-row2 t1-row2--12 t1-fsheet__acts">${button('Đặt lại', { variant: 'secondary', full: true })}${button('Áp dụng', { full: true })}</div></div>`;
};

/** AppBar Material: cao 56, nền surface, không gạch dưới; leading ← 56 (hẹp) + titleSpacing 0 / web không leading + titleSpacing 16; tiêu đề headingH4 w700. */
export const materialBar = (split) => `<header class="t1-mbar${split ? ' t1-mbar--split' : ''}">${split ? '' : `<button type="button" class="t1-mbar__back" aria-label="Quay lại">${icon('chevronLeft')}</button>`}<h1 class="t1-h4">Chi tiết hoạt động</h1></header>`;

/**
 * AuditDetailRow: giá trị ≤ 24 ký tự, một dòng → nhãn bodyDefault textSecondary ↔ giá trị bodyDefault w700 phải (+ nút sao chép 44, icon 18).
 * Dài hơn 24 ký tự (hoặc nhiều dòng) → xếp dọc: hàng nhãn (+ nút sao chép), khe 4, giá trị w700 canh trái, cao dòng 1.4 (monospace nếu sao chép được).
 */
export const arow = (l, val, copy = false) => {
  const btn = copy ? `<button type="button" class="t1-copy" aria-label="Sao chép mã theo dõi">${icon('copy')}</button>` : '';
  if (val.length > 24 || val.includes('\n')) return `<div class="t1-drow t1-drow--block"><div class="t1-drow__head"><span>${esc(l)}</span>${btn}</div><b${copy ? ' class="is-mono"' : ''}>${esc(val)}</b></div>`;
  return `<div class="t1-drow"><span>${esc(l)}</span><b>${esc(val)}${btn}</b></div>`;
};
/**
 * Một phần của thẻ chi tiết (iPhone, impeccable live 2026-11-25): tiêu đề w600 (+ nhãn), các dòng nhãn bodyDefault textSecondary ↔ giá trị w600 phải.
 * Mã theo dõi: nhãn trên, mã monospace dưới, nút sao chép 44 bên phải; mã sự kiện thô ở cuối phần truy vết.
 */
const part = (title, inner, b = '') => `<section class="t1-adm__part"><div class="t1-dhead"><h3 class="t1-h4 t1-h4--600">${esc(title)}</h3>${b}</div>${inner}</section>`;
const prow = (l, val) => `<div class="t1-adm__row"><span>${esc(l)}</span><b>${esc(val)}</b></div>`;
const traceRow = () => `<div class="t1-adm__trace"><div><span>Mã theo dõi</span><b>${esc(TRACE_ID)}</b></div><button type="button" class="t1-adm__copy" aria-label="Sao chép mã theo dõi">${icon('copy')}</button></div>`;

function auditDetail(s, split, device) {
  const wrap = (body, t = '') => `<div class="t1-page t1-page--canvas">${split ? materialBar(split) : appBar('Chi tiết hoạt động', { back: true })}<div class="t1-scroll">${body}</div>${t}</div>`;
  if (s.loading) return wrap(centerLoading());
  if (s.notFound) return wrap(`<div class="t1-center"><div class="t1-failed2"><h2 class="t1-h4 t1-h4--600">Không tìm thấy hoạt động</h2><div class="t1-gap-sm"></div><p class="t1-small t1-text-center">Nhật ký không tồn tại hoặc không thuộc tổ chức hiện tại.</p><div class="t1-gap-lg"></div>${button('Thử lại')}</div></div>`);
  const a = AUDIT.find((x) => x.id === s.id);
  const gone = badge('Không còn dữ liệu', 'warning');
  // Thứ tự: đầu màn (ô biểu tượng + tên hoạt động + "người · thời điểm") → nhãn kết quả → hộp vàng (không còn người thực hiện) → một thẻ: Dữ liệu thay đổi · Ngữ cảnh · Đối tượng · Thông tin truy vết.
  const changes = a.changes ? part('Dữ liệu thay đổi', a.changes.map(([f, before, after]) => `<div class="t1-adm__change"><span>${esc(f)}</span><span>Trước: ${esc(before)}</span><b>Sau: ${esc(after)}</b></div>`).join('')) : '';
  const body = `<div class="t1-list t1-adm">
    <div class="t1-orgm__head"><div class="t1-orgm__icon" aria-hidden="true">${icon(a.icon)}</div><div><h2>${esc(a.title)}</h2><p>${esc(`${a.actor} · ${a.at}`)}</p></div></div>
    <div class="t1-adm__result">${badge('Thành công', 'success')}</div>
    ${a.actorUnavailable ? `<div class="t1-adm__warn">${warnBox('Không còn thông tin người thực hiện', 'Thông tin người thực hiện không còn khả dụng tại thời điểm xem.')}</div>` : ''}
    ${card(`${changes}
      ${part('Ngữ cảnh', prow('Người thực hiện', a.actor) + prow('Loại chủ thể', a.actorRole), a.actorUnavailable ? gone : '')}
      ${part('Đối tượng', prow(a.subjectType, a.subject) + (a.subjectId ? prow('ID đối tượng', a.subjectId) : ''), a.legacy ? badge('Thông tin hiện tại', 'neutral') : '')}
      ${part('Thông tin truy vết', `${prow('Thời điểm', a.at.replace(' ', ' · '))}${prow('Nguồn', 'Tenant App')}${traceRow()}<p class="t1-adm__code">${esc(a.code)}</p>`)}`, 't1-adm__card')}
  </div>`;
  return wrap(body, s.toast ? toast('success', 'Đã sao chép', 'req_7f3a9c21e0b4d6a8b1e5f3c8d19f02', { device }) : '');
}
```

`app/web/audit.js:7-62`

```js
/**
 * Web (≥ 840) — bảng toàn màn, chọn qua impeccable live (2026-11-24): app bar + phụ đề; thanh công cụ (chip trái, ô tìm + bộ lọc phải);
 * cột 1120: dòng thời gian lọc → bảng (Hoạt động | Người thực hiện | Đối tượng: loại + tên | Thời điểm) → "Tải thêm". Chi tiết mở toàn màn (←).
 */
function auditTable(s) {
  const days = s.days || 30;
  const sub = s.forbidden ? 'Chưa được cấp quyền' : s.error ? 'Không tải được dữ liệu' : `${s.empty || s.noResults ? 0 : AUDIT_TOTAL} hoạt động trong ${days} ngày`;
  const items = s.category === 'Thành viên' ? AUDIT.filter((a) => ['a3', 'a5'].includes(a.id)) : AUDIT;
  const who = (a) => (a.actorRole && a.actorRole !== '—' ? `${a.actor} (${a.actorRole})` : a.actor);
  const ic = (a) => `<span class="t1-aic" aria-hidden="true">${icon(a.icon)}</span>`;
  const th = `<div class="t1-utable__tr t1-utable__th t1-atable__tr" role="row"><span role="columnheader">Hoạt động</span><span role="columnheader">Người thực hiện</span><span role="columnheader">Đối tượng</span><span role="columnheader">Thời điểm</span><span></span></div>`;
  let content;
  const state = s.forbidden ? 'forbidden' : s.error ? 'error' : s.empty ? 'empty' : s.noResults ? 'noResults' : '';
  if (state) content = `<div class="t1-utable t1-utable--state">${auditEmpty(state)}</div>`;
  else if (s.loading) {
    content = `<div class="t1-utable" role="table" aria-busy="true" aria-label="Đang tải">${th}${[0, 1, 2, 3, 4].map(() => `<div class="t1-utable__tr t1-utable__tr--skel t1-atable__tr"><span class="t1-atable__act">${skeleton({ w: 36, h: 36 })}${skeleton({ w: 180, h: 16 })}</span><span>${skeleton({ w: 140 })}</span><span class="t1-skelcol">${skeleton({ w: 60, h: 10 })}${skeleton({ w: 120 })}</span><span>${skeleton({ w: 110 })}</span><span></span></div>`).join('')}</div>`;
  } else {
    content = `<div class="t1-utable" role="table" aria-label="Lịch sử quản trị">${th}
      ${items.map((a) => `<button type="button" class="t1-utable__tr t1-atable__tr" role="row"><span class="t1-atable__act">${ic(a)}<span><b>${esc(a.title)}</b>${a.legacy ? badge('Thông tin hiện tại', 'neutral') : ''}</span></span><span class="t1-atable__sub">${esc(who(a))}</span><span class="t1-atable__sub"><small>${esc(a.subjectType)}</small>${esc(a.subject)}</span><span class="t1-utable__num">${esc(a.at)}</span>${icon('chevronRight', 't1-utable__chev')}</button>`).join('')}</div>
      <div class="t1-amore">${button('Tải thêm', { variant: 'secondary' })}</div>`;
  }
  const tools = `<div class="t1-utools"><div class="t1-atools__chips">${chipRow(['Tất cả', 'Thành viên', 'Vai trò', 'Tổ chức'], s.category || 'Tất cả')}</div>
    <div class="t1-utools__find">${searchBar('Tìm người thực hiện hoặc hoạt động', s.query || '')}${iconButton('tune', days !== 30 ? 'Bộ lọc (đang áp dụng)' : 'Bộ lọc', { size: 20, dot: days !== 30 })}</div></div>`;
  return `<div class="t1-page t1-page--canvas">${appBar('Lịch sử quản trị', { back: true, subtitle: sub })}${tools}
    <div class="t1-scroll"><div class="t1-uwrap"><p class="t1-small t1-atime2">Thời gian: ${days} ngày gần đây · Mới nhất trước</p>${content}</div></div></div>`;
}

export function auditPage(v) {
  const s = AUDIT_STATES[v.state];
  const overlay = s.sheet ? adaptiveSheet(v.width, auditFilter(), '', { title: 'Bộ lọc nhật ký nền tảng' }) : '';
  return { page: auditTable(s), overlay };
}

function auditDetail(s, device) {
  const wrap = (body, t = '') => `<div class="t1-page t1-page--canvas">${materialBar(false)}<div class="t1-scroll">${body}</div>${t}</div>`;
  if (s.loading) return wrap(centerLoading());
  if (s.notFound) return wrap(`<div class="t1-center"><div class="t1-failed2"><h2 class="t1-h4 t1-h4--600">Không tìm thấy hoạt động</h2><div class="t1-gap-sm"></div><p class="t1-small t1-text-center">Nhật ký không tồn tại hoặc không thuộc tổ chức hiện tại.</p><div class="t1-gap-lg"></div>${button('Thử lại')}</div></div>`);
  const a = AUDIT.find((x) => x.id === s.id);
  // Thiết kế lại qua impeccable live (2026-11-24): cột 720; đầu trang (ô biểu tượng + tên hoạt động + "người · thời điểm" + "Thành công")
  // → (hộp vàng khi không còn thông tin người thực hiện) → một thẻ, 4 phần ngăn gạch: Thay đổi (Trước gạch ngang → Sau nổi) · Ngữ cảnh ·
  // Đối tượng · Thông tin truy vết (+ mã sự kiện thô, chữ nhỏ).
  const gone = badge('Không còn dữ liệu', 'warning');
  const part = (t, inner, b = '') => `<div class="t1-adpart"><div class="t1-adpart__head"><h3>${esc(t)}</h3>${b}</div>${inner}</div>`;
  const change = a.changes ? part('Thay đổi', a.changes.map(([f, b4, af]) => `<div class="t1-adchange"><span class="t1-adchange__f">${esc(f)}</span><span class="t1-adchange__v"><span class="t1-adchange__before">Trước: ${esc(b4)}</span>${icon('chevronRight', 't1-adchange__arrow')}<b>Sau: ${esc(af)}</b></span></div>`).join('')) : '';
  const body = `<div class="t1-orgp">
    <div class="t1-orgp__head"><span class="t1-aic t1-aic--48" aria-hidden="true">${icon(a.icon)}</span><div><h1>${esc(a.title)}</h1><p>${esc(a.actor)} · ${esc(a.at)}</p></div><span class="t1-adok"><span class="t1-pill">Thành công</span></span></div>
    ${a.actorUnavailable ? `<div class="t1-warnbox">${icon('alert')}<div><b>Không còn thông tin người thực hiện</b><p class="t1-small">Thông tin người thực hiện không còn khả dụng tại thời điểm xem.</p></div></div>` : ''}
    <section class="t1-orgsec">
      ${change}
      ${part('Ngữ cảnh', `<div class="t1-stack8">${arow('Người thực hiện', a.actor)}${arow('Loại chủ thể', a.actorRole)}</div>`, a.actorUnavailable ? gone : '')}
      ${part('Đối tượng', `<div class="t1-stack8">${arow(a.subjectType, a.subject)}${a.subjectId ? arow('ID đối tượng', a.subjectId) : ''}</div>`, a.legacy ? badge('Thông tin hiện tại', 'neutral') : '')}
      ${part('Thông tin truy vết', `<div class="t1-stack8">${arow('Thời điểm', a.at.replace(' ', ' · '))}${arow('Nguồn', 'Tenant App')}${arow('Mã theo dõi', TRACE_ID, true)}</div><p class="t1-small t1-adcode">${esc(a.code)}</p>`)}
    </section>
  </div>`;
  return wrap(`<div class="t1-col" style="max-width:720px">${body}</div>`, s.toast ? toast('success', 'Đã sao chép', 'req_7f3a9c21e0b4d6a8b1e5f3c8d19f02', { device }) : '');
}
```

`styles/t1.css:321-358`

```css
/* ------------------------------------------------ Lịch sử quản trị (iPhone, impeccable live 2026-11-25; web ở t1-web.css) */
.t1-utop__chips { padding: 0 16px 12px; overflow-x: auto; }
.t1-atimem { flex: none; padding: 12px 16px 0; }
.t1-alist--days { gap: 0; padding-bottom: 34px; }
.t1-alist--days .t1-more { padding-top: 16px; }
.t1-aday__title { margin: 12px 0 6px; font-size: 13px /*fs-sm*/; line-height: 20px; font-weight: 600; color: #0E1116 /*text-primary*/; font-variant-numeric: tabular-nums; }
.t1-aday__box { border: 1px solid #D0D5DA /*border-strong*/; border-radius: 12px /*radius-card*/; background: #FFFFFF /*surface-default*/; overflow: hidden; }
.t1-aday__row { display: flex; align-items: center; gap: 12px; width: 100%; padding: 12px; border: 0; background: transparent; text-align: left; color: #0E1116 /*text-primary*/; cursor: pointer; }
.t1-aday__row + .t1-aday__row { border-top: 1px solid #E5E8EB /*border-default*/; }
.t1-aday__row:hover { background: #F8FAFB /*neutral-50*/; }
.t1-aday__row:focus-visible { outline-offset: -2px; }
.t1-aday__time { flex: 0 0 40px; align-self: flex-start; font-size: 13px /*fs-sm*/; line-height: 22px; font-weight: 600; color: #4A535E /*text-secondary*/; font-variant-numeric: tabular-nums; }
.t1-aday__text { flex: 1; min-width: 0; display: flex; flex-direction: column; overflow-wrap: anywhere; font-size: 13px /*fs-sm*/; line-height: 20px; font-weight: 500; color: #4A535E /*text-secondary*/; }
.t1-aday__name { display: flex; flex-wrap: wrap; align-items: center; gap: 2px 8px; }
.t1-aday__name b { font-size: 14px /*fs-md*/; line-height: 22px; font-weight: 600; color: #0E1116 /*text-primary*/; }
.t1-aday__name .t1-badge { border: 1px solid #E5E8EB /*border-default*/; }
.t1-aday__go { flex: none; font-size: 18px; color: #6B7480 /*icon-secondary*/; }

/* ------------------------------------------------ Chi tiết hoạt động (iPhone, impeccable live 2026-11-25; web ở t1-web.css) */
.t1-adm { padding-bottom: 34px; }
.t1-adm .t1-orgm__head h2 { font-size: 20px /*fs-xl*/; line-height: 28px; }
.t1-adm__result { margin-bottom: 16px; display: flex; }
.t1-adm__warn { margin-bottom: 12px; }
.t1-adm__card { overflow: hidden; }
.t1-adm__part { display: flex; flex-direction: column; gap: 10px; padding: 16px; }
.t1-adm__part + .t1-adm__part { border-top: 1px solid #E5E8EB /*border-default*/; }
.t1-adm__part .t1-badge--neutral { border: 1px solid #E5E8EB /*border-default*/; }
.t1-adm__row { display: flex; justify-content: space-between; gap: 16px; font-size: 14px /*fs-md*/; line-height: 22px; }
.t1-adm__row span { flex: none; font-weight: 500; color: #4A535E /*text-secondary*/; }
.t1-adm__row b { min-width: 0; overflow-wrap: anywhere; text-align: right; font-weight: 600; color: #0E1116 /*text-primary*/; }
.t1-adm__change { display: flex; flex-direction: column; font-size: 14px /*fs-md*/; line-height: 22px; font-weight: 500; color: #4A535E /*text-secondary*/; }
.t1-adm__change b { font-weight: 600; color: #26612F /*text-brand*/; }
.t1-adm__trace { display: flex; align-items: center; gap: 8px; }
.t1-adm__trace > div { flex: 1; min-width: 0; }
.t1-adm__trace span { display: block; font-size: 14px /*fs-md*/; line-height: 22px; font-weight: 500; color: #4A535E /*text-secondary*/; }
.t1-adm__trace b { overflow-wrap: anywhere; font-family: "JetBrains Mono",ui-monospace,SFMono-Regular,Menlo,monospace /*font-mono*/; font-size: 13px /*fs-sm*/; line-height: 20px; font-weight: 500; color: #0E1116 /*text-primary*/; }
.t1-adm__copy { display: grid; place-items: center; flex: none; width: 44px; height: 44px; margin-right: -10px; padding: 0; border: 0; background: transparent; font-size: 18px; color: #26612F /*icon-brand*/; cursor: pointer; }
.t1-adm__code { margin: 0; overflow-wrap: anywhere; font-family: "JetBrains Mono",ui-monospace,SFMono-Regular,Menlo,monospace /*font-mono*/; font-size: 12px /*fs-xs*/; line-height: 18px; color: #4A535E /*text-secondary*/; }
```

`styles/t1-web.css:158-184`

```css
.t1-atools__chips .t1-hscroll { padding: 12px 0; }
.t1-atime2 { margin: 0 0 16px; }
.t1-atable__tr { grid-template-columns: minmax(260px, 1.6fr) 1.2fr 1.2fr 150px 24px; }
.t1-atable__act { display: flex; align-items: center; gap: 12px; min-width: 0; }
.t1-atable__act > span:last-child { display: flex; flex-wrap: wrap; align-items: center; gap: 8px; min-width: 0; }
.t1-atable__act b { font-weight: 600; }
.t1-atable__sub { display: flex; flex-direction: column; min-width: 0; }
.t1-atable__sub small { font-size: 12px /*fs-xs*/; color: #4A535E /*text-secondary*/; }
.t1-aic { display: grid; place-items: center; flex: none; width: 36px; height: 36px; border-radius: 8px /*radius-3*/; background: #EBF4EE /*surface-brand*/; color: #26612F /*icon-brand*/; }
.t1-aic .icon { width: 18px; height: 18px; }
.t1-amore { display: flex; justify-content: center; margin-top: 20px; }
.t1-utable--state > .t1-aempty { flex: 1 0 360px; display: grid; place-items: center; }
.t1-utable--state .t1-oempty__card { border: 0; background: transparent; box-shadow: none; }

/* Chi tiết hoạt động: đầu trang + một thẻ 4 phần ngăn gạch; Thay đổi: Trước (gạch ngang) → Sau (nền brand). */
.t1-aic--48 { width: 48px; height: 48px; }
.t1-aic--48 .icon { width: 22px; height: 22px; }
.t1-adok { margin-left: auto; align-self: flex-start; }
.t1-adpart + .t1-adpart { margin-top: 20px; padding-top: 20px; border-top: 1px solid #E5E8EB /*border-default*/; }
.t1-adpart__head { display: flex; align-items: center; justify-content: space-between; gap: 8px; margin-bottom: 12px; }
.t1-adpart__head h3 { margin: 0; font-size: 13px /*fs-sm*/; line-height: 18px; font-weight: 700; color: #4A535E /*text-secondary*/; }
.t1-adchange { display: flex; flex-direction: column; gap: 8px; }
.t1-adchange + .t1-adchange { margin-top: 12px; }
.t1-adchange__f { font-size: 13px /*fs-sm*/; font-weight: 600; color: #0E1116 /*text-primary*/; }
.t1-adchange__v { display: flex; flex-wrap: wrap; align-items: center; gap: 8px; font-size: 14px /*fs-md*/; }
.t1-adchange__before { color: #4A535E /*text-secondary*/; text-decoration: line-through; text-decoration-color: #D0D5DA /*border-strong*/; }
.t1-adchange__arrow { width: 18px; height: 18px; color: #9AA3AD /*icon-muted*/; }
```

`styles/t1.css:598-601`

```css
.t1-ring { display: grid; place-items: center; width: 64px; height: 64px; flex: 0 0 auto; border-radius: 999px /*radius-pill*/; background: #F6F8F9 /*surface-canvas*/; color: #4A535E /*text-secondary*/; font-size: 28px; }
.t1-ring--warning { background: #F9F1E2 /*surface-warning*/; color: #935A0A /*text-warning*/; }
.t1-ring--danger { background: #F8ECEC /*surface-danger*/; color: #B53232 /*text-danger*/; }
.t1-ring--56 { width: 56px; height: 56px; }
```


CSS đã có: `.t1-utable*`, `.t1-utools*`, `.t1-uwrap`, `.t1-avatar`, `.t1-skel*` (10-8h); `.t1-orgm__head`, `.t1-orgp__head`, `.t1-orgsec` (10-8g).

### Ánh xạ phần tử → Flutter

| Prototype | Flutter |
|---|---|
| `.t1-rolecard` | `RoleCard`: `VCard(onTap, padding: zero)`; phần trên, gạch, chân thẻ |
| `.t1-rtable__tr` | `AdminTable(columns: [AdminTableColumn('Vai trò hệ thống', flex: 1.4, minWidth: 280), AdminTableColumn('Thành viên đang giữ vai trò')])` |
| `.t1-rolecard__av` 28 / 36 | `DetailAvatar(size: 28 / 36)` |
| `.t1-atable__tr` | `AdminTable` 4 cột: Hoạt động (1.6, min 260), Người thực hiện 1.2, Đối tượng 1.2, Thời điểm rộng 150 |
| `.t1-aic` 36 / 48 | ô nền `surfaceBrand`, bo 8, icon 18 / 22 `textBrand` |
| `.t1-aday__*` | `AuditDaySection` (tiêu đề ngày + `VCard` nhiều dòng) |
| `.t1-adm__part`, `.t1-adpart` | `DetailPart(title, trailing, children)`, gạch giữa các phần |
| `.t1-adchange` web | "Trước" gạch ngang, mũi tên, "Sau" nền `surfaceBrand` bo tròn |
| `.t1-adm__trace`, `arow(…, copy)` | dòng mã theo dõi monospace + `AuditCopyButton` 44 (có sẵn) |
| `auditEmpty` | `AuditLogEmptyView` (có sẵn); trong bảng web bỏ viền thẻ (`flat: true`) |

## Bảng "Đang làm gì"

| Thứ bị thay | Đang làm gì | Sau khi sửa | Test giữ hành vi |
|---|---|---|---|
| `RolesAreaShell`, `AuditAreaShell` | Hai cột ≥ 840 | Một trang (**đổi có chủ đích**) | `w2_wide_layout_test` 3, 4, 5, 14, 15 viết lại |
| Vai trò | Lỗi → "Thử lại"; bấm thẻ mở chi tiết; "Đang dùng" | Nguyên; mũi tên có ở mọi thẻ | có sẵn 4 ca; T0: `detail lists holders`, `unknown code shows Không tìm thấy vai trò` |
| Chi tiết vai trò | Mở bằng `extra` hoặc theo mã | Nguyên | T0: `deep link loads the role` |
| Lịch sử | Tìm (350 ms), chip, sheet, chấm lọc, "Tải thêm", 4 khối trạng thái, ← | Nguyên | có sẵn 8 ca + cubit 8 + 2 ca tìm |
| Sheet lọc | 3 nhóm, Đặt lại, Áp dụng | 2 nhóm (**đổi có chủ đích**, Q3) | có sẵn, viết lại |
| Chi tiết | 4 thẻ + cảnh báo + thay đổi, che dữ liệu, sao chép | Một thẻ 4 phần, đủ dữ liệu | có sẵn `audit_log_detail_*` 4 file (đổi nhãn Q14) |
| | Không có thay đổi nhưng có `beforeRedacted` / trạng thái thô | Giữ nhánh này trong phần "Dữ liệu thay đổi" | có sẵn `renders independent redaction cells…` |

## Review Focus

1. **Lọc 24 giờ lúc 00:10 sáng:** vẫn ra hoạt động tối hôm trước. Test ở Task 2.
2. **Máy đặt múi giờ khác Việt Nam:** "7 ngày" vẫn theo ngày Việt Nam. Test ở Task 2 (`clock` UTC 18:00 = 01:00 hôm sau VN).
3. **Tải lại trang (F5) ở `/more/roles/staff` và `/more/audit-logs/:id`:** hiện đúng, ← về danh sách. Test ở Task 1, 3.
4. **Hoạt động không có người thực hiện, không có đối tượng, 30 trường thay đổi:** không tràn ở 320 và 840. Test ở Task 3.
5. **Vai trò có 12 người giữ:** thẻ và bảng cắt một dòng, chi tiết liệt kê đủ. Test ở Task 1.

---

### Task 0: Test giữ hành vi trên code cũ

**Files:**
- Modify: `apps/erp/test/features/iam/presentation_module/widgets/{organization_roles_page,organization_role_detail_page}_test.dart`

- [ ] **Step 1: Viết ca T0 trong bảng** ở 390 × 844.
- [ ] **Step 2: Chạy, phải xanh trên code cũ** — `cd apps/erp && flutter test test/features/iam/presentation_module/widgets/organization_roles_page_test.dart test/features/iam/presentation_module/widgets/organization_role_detail_page_test.dart test/features/iam/presentation_module/widgets/organization_audit_logs_page_test.dart`

### Task 1: Prototype + Vai trò (ID-19)

**Files:**
- Modify: prototype `app/roles.js`, `app/web/roles.js`, `app/audit.js`, `app/web/audit.js`, `app/admin-data.js`, `app/cases.js`, `tests/t1.test.mjs`, `README.md` (mục 49–52)
- Create: `roles/widgets/{role_card,roles_narrow,roles_wide,role_detail_narrow,role_detail_wide}.dart`, `apps/erp/test/features/iam/presentation_module/roles_audit_golden_test.dart`
- Modify: `roles/roles_area_shell.dart`, `roles/views/{organization_roles_page,organization_role_detail_page}.dart`, `core/router/app_router.dart:802-866`
- Test: hai file Task 0, `w2_wide_layout_test.dart` (3, 5, 14)

**Interfaces:**
- Consumes: `AdminTable`, `AdminTablePage`, `DetailAvatar`, `DetailHeaderNarrow`, `DetailIconTile`, `isWideLayout`.
- Produces: `RolesAreaShell({super.key, required Widget child, invitations, members, cubit})`; `RolesLoadError({super.key, required VoidCallback onRetry})` dùng chung danh sách và chi tiết.

- [ ] **Step 1: Prototype** — `roles` ca `loading` (hẹp `centerLoading()`, phụ đề hai khung "Đang tải vai trò"); `auditFilter` hai nhóm, tiêu đề sheet Q1; `auditDetail` hai khung nhãn Q14; toast Q13; `auditRow` / bảng web vẽ nhãn kết quả khi `a.result` có; thêm mục mẫu `a7` (`result: ['Bị chặn', 'warning']`, "Loại thành viên khỏi tổ chức", Nguyễn Thị Lan, 20/11/2026 08:15, Trần Văn Minh) chỉ dùng ở ca mới `['blocked', 'Có hoạt động bị chặn', …]`; ca `not-found` giữ. `ROLES` mô tả `store_owner` "Quản lý toàn bộ cửa hàng", bỏ `shortDesc`. `node --test` PASS; `node tools/capture.mjs roles`, `audit`; chép lại ảnh ở mục Ảnh và `audit__blocked` hai khung.
- [ ] **Step 2: Viết test**

```dart
testWidgets('390 loading shows a spinner and Đang tải vai trò', …)      // không có '0 vai trò hệ thống'
testWidgets('1280 loading shows four skeleton rows', …)
testWidgets('390 cards: badge, arrow on every card, holders footer', …)
testWidgets('1280 table opens detail by url, back returns', …)
testWidgets('detail load error can be retried', …)                      // Q5
testWidgets('deep link /more/roles/staff at 1280: back goes to the list', …)
testWidgets('12 holders: one line in list, all in detail', …)
testWidgets('320 at text scale 2.0 does not overflow', …)
```

- [ ] **Step 3: Chạy → FAIL** — lệnh Task 0 Step 2 thêm `test/features/iam/presentation_module/w2_wide_layout_test.dart`
- [ ] **Step 4: Cài đặt** Q4, Q5, Q19; router bỏ khối "Chọn một vai trò để xem chi tiết."
- [ ] **Step 5: Chạy → PASS** (lệnh Step 3)
- [ ] **Step 6: Golden** `roles__{list,loading,failed,detail,detail-empty}` × 2. So ảnh, ghi lệch.

### Task 2: Logic lịch sử

**Files:**
- Modify: `logic/tenant_audit_{filter,logs_cubit,logs_state,event_catalog}.dart`, `audit_logs/mappers/tenant_audit_ui_mapper.dart`, `audit_logs/models/audit_log_filter_criteria.dart`, `audit_logs/widgets/audit_log_filter_bottom_sheet.dart`, `audit_logs/views/audit_log_detail_page.dart` (chỉ Q11)
- Test: `audit_logs/{tenant_audit_logs_cubit,tenant_audit_logs_cubit_search_remediation,tenant_audit_event_catalog,tenant_audit_ui_mapper_labels}_test.dart`, `widgets/audit_log_filter_bottom_sheet_test.dart`

**Interfaces:**
- Produces:

```dart
enum TenantAuditRange { h24, d7, d30 }
// TenantAuditFilter: final TenantAuditRange range (mặc định d30); copyWith(range); factory TenantAuditFilter.forRange(TenantAuditRange range, {required DateTime nowIct});
//   last30Days giữ, gọi forRange(d30)
// TenantAuditLogsCubit: Future<void> applyRangeAndResult(TenantAuditRange range, TenantAuditLogResult? result);
// TenantAuditLogsState: IamUiFailure? loadMoreFailure (copyWith + clearLoadMoreFailure); cubit.clearLoadMoreFailure()
// AuditLogFilterCriteria({TenantAuditRange range = TenantAuditRange.d30, AuditLogStatus? status}); bool get isFilterActive => range != d30 || status != null
```

- [ ] **Step 1: Viết test**

```dart
test('h24 searches exactly the last 24 hours, kept across load more', …) // clock 2026-11-25 00:10 VN → from == 2026-11-23T17:10:00Z cho cả hai trang
test('d7 follows Vietnam days on a UTC device', …)                       // clock 2026-11-24T18:00Z → to = hết ngày 25/11 VN, from = đầu ngày 19/11 VN
test('range makes the filter advanced', …)
test('stale search response is dropped', …)
test('load more failure keeps items and status', …)                      // cả mã không quyền
test('partial titles of two or more words match events', …)              // 'tạm ngừng' → membershipDeactivated; 'Thành' → không khớp; 'thành viên' → khớp các tên có cụm
test('sourceApp tenant_app reads Ứng dụng', …)
testWidgets('filter sheet has two groups; reset returns to 30 ngày and applies', …)
testWidgets('detail page requests once', …)                              // đếm GetTenantAuditLogQuery == 1
```

- [ ] **Step 2: Chạy → FAIL** — `flutter test test/features/iam/presentation_module/audit_logs test/features/iam/presentation_module/widgets/audit_log_filter_bottom_sheet_test.dart`
- [ ] **Step 3: Cài đặt** Q2, Q3, Q6–Q7, Q9–Q11, Q14 (mapper), Q16.
- [ ] **Step 4: Chạy → PASS** (lệnh Step 2)

### Task 3: Lịch sử quản trị (ID-20) + dọn

**Files:**
- Create: `audit_logs/widgets/{audit_narrow,audit_wide,audit_day_section,audit_detail_narrow,audit_detail_wide,detail_part}.dart`
- Modify: `audit_logs/audit_area_shell.dart`, `audit_logs/views/{organization_audit_logs_page,audit_log_detail_page}.dart`, `audit_logs/widgets/{audit_log_empty_view,audit_detail_row}.dart`, `core/router/app_router.dart:871-932`, `docs/requirements/TH-01-to-chuc-va-nguoi-dung.md`, `docs/refactor/PLAN.md`
- Delete: `audit_logs/widgets/{audit_log_item_card,audit_log_detail_body,audit_log_change_diff_item}.dart`, hai file Q17
- Test: `organization_audit_logs_page_test.dart`, `organization_audit_logs_localized_search_remediation_test.dart`, `audit_log_detail_*_test.dart` (4 file, trỏ sang widget mới), `audit_log_empty_view_test.dart`, `w2_wide_layout_test.dart` (4, 15), `w2_behavior_preservation_test.dart:531` (tiêu đề sheet)

**Interfaces:**
- Consumes: `AdminTable`, `AdminTablePage`, `AuditCopyButton`.
- Produces: `AuditAreaShell({super.key, required Widget child, auditLogs, clockLocal, cubit})`; `AuditDetailNarrow / AuditDetailWide({super.key, required AuditLogItemUiModel log})` (chỉ thân, trang giữ `VAppBar`).

- [ ] **Step 1: Viết test**

```dart
testWidgets('390 groups by Vietnam day with times', …)                  // 2026-11-21T17:30Z → ngày 22/11/2026, 00:30
testWidgets('390 and 1280 show Bị chặn / Lỗi badges only', …)           // Q15
testWidgets('subtitle reads the selected range', …)                     // '24 hoạt động trong 24 giờ'
testWidgets('reopening the sheet shows the applied range', …)
testWidgets('range with no results offers Xóa bộ lọc, which also cancels typing', …) // Q7, Q8
testWidgets('load more failure shows a toast and keeps rows', …)
testWidgets('1280 table opens detail by url, back returns, deep link back works', …)
testWidgets('detail: network error is not reported as missing', …)      // Q12
testWidgets('copy toast reads Đã sao chép mã theo dõi.', …)
testWidgets('detail labels: Vai trò, Dữ liệu thay đổi, Mã nhật ký', …)
testWidgets('30 changes and missing actor do not overflow at 320 and 840', …)
```

- [ ] **Step 2: Chạy → FAIL** — `flutter test test/features/iam/presentation_module/widgets test/features/iam/presentation_module/w2_wide_layout_test.dart`
- [ ] **Step 3: Cài đặt** Q1, Q8, Q10, Q12, Q13, Q15, Q17, Q18, Q20; router bỏ khối "Chọn một mục lịch sử…".
- [ ] **Step 4: TH-01 US-07.2** — FR-01: "trong 24 giờ / 7 ngày / 30 ngày", tìm theo tên hoạt động từ hai từ; FR-02: "kết quả hiện khi là Lỗi / Bị chặn"; FR-03: "Vai trò" của người thực hiện, "Nguồn", "Mã nhật ký".
- [ ] **Step 5: Chạy → PASS**

Run: `cd apps/erp && flutter test test/features/iam && dart analyze lib test && dart run tool/check_feature_imports.dart`
Expected: PASS, không lỗi analyze mới, không vi phạm import mới

- [ ] **Step 6: Golden** `audit__{list,loading,no-results,forbidden,filter,filter-applied,blocked}`, `audit-detail__{detail,actor-unavailable,not-found,toast-copied}` × 2. So ảnh.
- [ ] **Step 7: PLAN.md** dòng Theme 1: 10-8i đã làm

## Kiểm tay (người dùng)

- [ ] Vai trò: xem, chi tiết, F5 ở chi tiết (web), mất mạng rồi "Thử lại".
- [ ] Lịch sử: tìm tên người, tìm "tạm ngừng", từng chip, 24 giờ / 7 ngày, "Đặt lại", "Tải thêm", chi tiết, sao chép mã.
- [ ] CHECKLIST ID-19, ID-20 cột "Mới".

## Kết quả

## Review
