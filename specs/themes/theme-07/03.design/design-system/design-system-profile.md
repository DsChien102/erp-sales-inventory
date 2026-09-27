---
id: DS-PROFILE
type: design-system-profile
theme: theme-07
title: "Theme 07 Design System Profile"
owner: BA
status: FROZEN
source_baseline: v3.13.0
---
# Design System Profile — Theme 07

## 1. Nguồn và version

> **Business/behavior authority:** Theme 7 Product documents, BJ/UC/decisions, behavioral contracts and Screen Design Contracts.
> **UI authority:** live Figma Design System v2.0.2 locked by `FIGMA-DS-LOCK.json`.
> **HTML role:** renderer/prototype and interaction evidence only; never a second Design System.

### 1. Authority chain

1. Product/BJ/UC/decision/behavioral contract — what the product must do, actor ownership, lifecycle, permission and authoritative effect.
2. Screen Design Contract — task, information, interaction, state, navigation and business composition requirement.
3. Figma DS Foundations → Components → Patterns → Templates — canonical UI expression, token, component anatomy, interaction conventions and visual rules.
4. Theme 7 Product composition — feature-specific combination of canonical DS assets.
5. HTML prototype — conformance renderer used for UX review, evidence and handoff.

### 2. Reuse rule

For every product surface, search/reuse in this order:

**Component → Pattern → Template → Product composition.**

- Prefix `V` is not the boundary of the Design System. `DS v2 / ...`, standalone canonical masters and approved templates are equally reusable when their responsibility matches.
- Do not recreate an existing canonical component inside product HTML.
- Do not encode business copy/status/entity values as a new DS variant.
- Missing capability is a DS gap and must enter `figma-ds/ds-gap-register.md`; HTML may not silently invent a new standard.

### 3. Foundation rule

- Live variables and live styles are canonical where they exist.
- Semantic tokens are consumed before primitive values.
- When a DS foundation is documented but not variableized, it may be used only as an explicitly documented fallback and must not be represented as a live variable.
- Direct conflicts between live Variable/Style and documentation are resolved through `ds-gap-register.md`, not by silent choice.

### 4. Figma DS lock artifacts

- `FIGMA-DS-LOCK.json`
- `figma-ds/figma-variable-manifest.json`
- `figma-ds/figma-style-manifest.json`
- `figma-ds/figma-component-registry.json`
- `figma-ds/figma-pattern-template-registry.json`
- `figma-ds/ds-gap-register.md`

`FLUTTER-DS-LOCK.json` is retained only as historical evidence for pre-v2.0.0 releases and is no longer UI authority.

### 5. Conformance gates

A screen is final only when it is business-correct, mapped to exact Figma DS assets/variants, state-covered, HTML-rendered, visually verified at 402×874, interaction-verified and cumulatively regression-verified.


### 6. Live Figma revalidation cho v3.13.0

Nguồn trực tiếp: file `QVJolM5tAdFKkhP7RIwe3y`, page `505:5890 — DS v2 - 02 Components`.

Các component canonical được kiểm trực tiếp trước khi redesign valuation cluster:

- `VAppBar` `547:1594`;
- `VButton` `521:529`; `VTextField` `522:7186`; `VSearchBar` `522:7245`;
- `VSegmentedControl` `1049:9619`; `VBadge` `525:309`; `VChip` `522:7449`;
- `DS v2 / List Row` `525:519`; `Info Row` `525:351`; `Key-value Row` `525:358`;
- `Entity Card` `525:539`; `Summary Card` `525:552`;
- `VBanner` `526:4215`; `VEmptyState` `526:4352`; `Readiness Item` `526:4442`;
- `VBottomSheet` `4695:6353`.

Variable collections được kiểm trực tiếp: `Color Primitive`, `Color Semantic`, `Dimension`, `Opacity`. Các variable trọng yếu: `Layout/Mobile width = 402`, `Layout/Mobile height = 874`, `Layout/Mobile edge = 16`, `Touch/Minimum = 44`, `Space/1..8 = 4/8/12/16/20/24/32`, `Radius/3..6 = 8/12/16/20`, `Opacity/Disabled = 0.4`, `Opacity/Overlay = 0.48`.

HTML phải consume semantic CSS variables/canonical composition; không sao chép mã React/Tailwind do Figma MCP sinh ra.

## 2. Component subset sử dụng

Xem generated component usage registry và Screen Contracts.

## 3. Quy ước áp dụng

Các quy ước được giữ nguyên trong nội dung nguồn ở mục 1 và các Screen Contracts.

## 4. Extension được chấp thuận

Chỉ các extension đã có trong source/registry v3.10.1; migration không tạo extension mới.

## 5. Exception

Không bổ sung exception mới trong migration.
