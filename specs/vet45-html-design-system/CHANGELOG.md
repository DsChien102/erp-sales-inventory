# 1.5.0

- Re-baseline naming: 87/87 master names are immutable Figma source identities; Flutter public API and HTML selectors are separate trace fields, never replacement names.
- Rebuilt live token layer from current Figma variables/styles/effects; documented Figma↔Flutter drift and the Icon/Thin–Icon/Thick WEB syntax collision.
- Fixed the structural cause of broken catalog previews: 214/214 `v-*` classes used by `index.html` now have CSS implementation (0 missing).
- Rebuilt exact anatomy for `DS v2 / Avata Card`, `DS v2 / Product Result Card`, `DS v2 / Order Line Row`, Payment & Receivable rows, `VToast`, `VEmptyState`, `VModal`, and named Numeric Keypad children.
- Removed silent/semantic icon substitutions in the affected masters. Product image and payment glyphs use their source Figma vectors; Order Line uses its custom source vector instead of an invented `box` mapping.
- Added canonical registry, live token snapshot and exact Flutter `VIcons` semantic mapping contract.
- Added release gates for 0 missing catalog CSS classes, 0 missing catalog icons, and exact Figma heading identity.
- Removed stale pre-canonical rules for the six user-reported broken components; each root now has a single canonical implementation.
- Materialized exact Figma SVGs for the critical icon set used by those previews and semantic toast/payment examples; added shape-completeness gates.

# 1.4.0

- Re-baseline runtime HTML/CSS theo node/component master trực tiếp từ Figma DS.
- Khôi phục đầy đủ `src/` + `contracts/` bị thiếu trong working package; catalog không còn fallback CSS.
- Sửa anatomy/geometry cho Actions, selection controls, Navigation, Data Display, Feedback, Overlay, Patterns và 8 mobile templates.
- FAB bỏ shadow tự chế; selection controls tách visual size khỏi touch target; Metric/Product/Payment sửa theo master thật.
- Modal/Numeric Keypad/Bottom Sheet và Sticky Footer/Keyboard-safe/Confirmation được khóa theo exact Figma geometry.
- Structural gate 87/87 PASS; browser-wide pixel gate không được đánh PASS khi Chromium sandbox không ổn định.

# 1.3.0

- Root `index.html` is now the full Component Explorer, not a redirect/partial showcase.
- Renders all 65 Figma component masters and all 22 pattern/template masters as review cards.
- Exposes Figma node ID, canonical HTML selector and complete variant/property axes for every master.
- Adds searchable/category-filterable catalog for day-to-day DS review.
- Fixes focused/error state parity for Money/Select/Date/Search chrome.
- Fixes checkbox on-state when no explicit check icon is supplied.
- Fixes legacy Action Row sample anatomy/typography compatibility.
- Keeps `showcase/index.html` as curated overview, with link to the full explorer.

# Changelog

## 1.3.0
- Re-baseline Figma DS v2 và cross-check Flutter DS 1.4.1.
- Thêm public visual API coverage, compound Card/Combobox/Table/Verification Code/form mappings.
- Khóa 35 approved icon source node IDs; bỏ silent icon fallback.
- Thêm parity matrix và drift governance.


## 1.1.0 — 2026-09-29

### QA parity rebuild

Release này thay thế cách làm “bản rút gọn” của v1.0.0 bằng inventory và release gate dựa trực tiếp trên Figma DS v2.0.3.

**Đã sửa:**

- Bổ sung inventory đầy đủ: 65 component masters và 22 pattern/template masters.
- Bổ sung các master bị thiếu ở v1: `VBottomSheet`, `Context Header`, `Payment & Receivable Summary Row`, `Select Sheet`, `Form Sheet`, Financial Disclosure và đủ 8 Mobile Page Templates.
- Sửa `VButton/Danger`: source Figma là **white + Danger border/text**, Pressed = Danger/50; v1 đã thể hiện sai kiểu filled red.
- Sửa `VBadge` visual height từ 24px → **30px**.
- Sửa `VChip` visual height từ 36px → **34px**.
- Sửa `VAppBar`: **402×56**, padding ngang 16, gap 8, không thêm bottom border ngoài source.
- Sửa input anatomy: 44px control, radius 8, Default border, Focused 2px Brand border, Error Danger border/helper, Disabled root opacity .4.
- Sửa Checkbox/Radio/Switch theo control geometry của source.
- Sửa List Row default/compact, semantic selected/pressed/disabled states.
- Sửa Banner/Toast/Empty/Loading/Progress/Skeleton/Readiness geometry.
- Bổ sung exact bottom sheet shell: top radius 20, handle 48×4, inset 16, bottom safe area 44.
- Bổ sung Sticky Footer 92/128, Action/Confirmation/Filter Sheet, Loading Overlay, Search & Filter Header, Search Results Dropdown.
- Bổ sung template CSS cho 8 archetype 402×874.
- Bổ sung traceability contracts và approved icon registry.
- Nâng QA từ existence-check thành release gate có master counts và critical parity assertions.

### Source issues không tự sửa

- Figma đang cho `Icon/Thin` và `Icon/Thick` cùng WEB code syntax `--vet45-v2-icon-stroke` dù giá trị 1 và 2 khác nhau. HTML DS giữ alias riêng và ghi issue trong `figma-source.json`.
- Source có tên `DS v2 / Avata Card` và variant `Defualt` / `Disable`. Contract giữ nguyên tên source để trace; HTML API normalize state.

## 1.0.0

Baseline đầu tiên. Phạm vi chỉ đủ chứng minh mô hình shared HTML DS; chưa đạt parity đầy đủ với Figma và QA chưa chặn được thiếu master/variant.
