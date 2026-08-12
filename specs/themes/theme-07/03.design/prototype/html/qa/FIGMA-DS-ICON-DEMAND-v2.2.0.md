# Figma DS Icon Demand Audit — v2.2.0 candidate

**497 declared state renders across 17 UIFs audited.**

> This is migration demand from the legacy Product renderer. It does not authorize raw Lucide usage. Canonical Product icon use must resolve through the approved VET45 Icon Library and `DS v2 / Icon` wrapper.

## Global icon demand

- `VIcons.chevronLeft` — 288 render occurrences — **APPROVED_ICON_LIBRARY** → `li:chevron-left`
- `VIcons.chevronRight` — 236 render occurrences — **APPROVED_ICON_LIBRARY** → `li:chevron-right`
- `VIcons.warning` — 83 render occurrences — **APPROVED_ICON_LIBRARY** → `li:triangle-alert`
- `VIcons.lock` — 78 render occurrences — **DS_SOURCE_GAP_NOT_IN_APPROVED_LIBRARY** → `li:lock`
- `VIcons.info` — 66 render occurrences — **APPROVED_ICON_LIBRARY** → `li:info`
- `VIcons.search` — 47 render occurrences — **APPROVED_ICON_LIBRARY** → `li:search`
- `VIcons.clock` — 40 render occurrences — **DS_SOURCE_GAP_NOT_IN_APPROVED_LIBRARY** → `li:clock`
- `VIcons.success` — 36 render occurrences — **APPROVED_ICON_LIBRARY** → `li:circle-check`
- `VIcons.close` — 23 render occurrences — **APPROVED_ICON_LIBRARY** → `li:x`
- `VIcons.inbox` — 21 render occurrences — **DS_SOURCE_GAP_NOT_IN_APPROVED_LIBRARY** → `li:inbox`
- `VIcons.description` — 14 render occurrences — **DS_SOURCE_GAP_NOT_IN_APPROVED_LIBRARY** → `li:file-text`
- `VIcons.arrowDropDown` — 11 render occurrences — **APPROVED_ICON_LIBRARY** → `li:chevron-down`
- `VIcons.check` — 11 render occurrences — **DS_SOURCE_GAP_NOT_IN_APPROVED_LIBRARY** → `li:check`
- `VIcons.refresh` — 4 render occurrences — **APPROVED_ICON_LIBRARY** → `li:refresh-cw`
- `VIcons.bolt` — 3 render occurrences — **DS_SOURCE_GAP_NOT_IN_APPROVED_LIBRARY** → `li:zap`
- `VIcons.inventory` — 3 render occurrences — **DS_SOURCE_GAP_NOT_IN_APPROVED_LIBRARY** → `contextual: li:package / li:layers`
- `VIcons.error` — 1 render occurrences — **APPROVED_ICON_LIBRARY** → `li:circle-x`
- `VIcons.history` — 1 render occurrences — **APPROVED_ICON_LIBRARY** → `li:history`

## Freeze blockers

- `VIcons.lock` requires `li:lock` but is not currently available as an approved Icon Library Product source.
- `VIcons.clock` requires `li:clock` but is not currently available as an approved Icon Library Product source.
- `VIcons.inbox` requires `li:inbox` but is not currently available as an approved Icon Library Product source.
- `VIcons.description` requires `li:file-text` but is not currently available as an approved Icon Library Product source.
- `VIcons.check` requires `li:check` but is not currently available as an approved Icon Library Product source.
- `VIcons.bolt` requires `li:zap` but is not currently available as an approved Icon Library Product source.
- `VIcons.inventory` requires `contextual: li:package / li:layers` but is not currently available as an approved Icon Library Product source.

## Rule

- Do not reuse the current hand-authored SVG registry during migration.
- Do not pull a glyph directly from the raw `Lucide Icons` vendor section.
- If a demanded glyph is absent from the approved Icon Library, add/approve it in Figma DS first, then materialize the exact asset and migrate Product usage.
